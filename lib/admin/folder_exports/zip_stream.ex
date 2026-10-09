defmodule Admin.FolderExports.ZipStream do
  @moduledoc """
  Encodes entries into a zip archive as a lazy stream of iodata, without ever
  holding a whole file in memory or writing a temporary file.

  Each entry is a map `%{path: String.t(), data: data}` where `data` is:

    * `:dir` for a directory (the path gets a trailing `/`),
    * a binary, or
    * an enumerable of binaries (for instance an S3 download stream).

  Entries are deflated and written with a data descriptor, so their sizes do
  not need to be known upfront. The archive uses zip64 structures only where a
  size, an offset or the entry count requires it.

  `:on_entry` (optional) is called with each entry once it has been fully
  written, which lets the caller report progress.
  """

  import Bitwise

  @max_32 0xFFFFFFFF
  @max_16 0xFFFF
  @utf8_flag 0x0800
  @descriptor_flag 0x0008

  @doc """
  Returns a stream of iodata chunks that make up the zip archive.
  """
  def encode(entries, opts \\ []) do
    on_entry = Keyword.get(opts, :on_entry, fn _ -> :ok end)
    {dos_time, dos_date} = dos_datetime(Keyword.get(opts, :now, NaiveDateTime.utc_now()))

    Stream.resource(
      fn ->
        %{
          entries: start(entries),
          current: nil,
          offset: 0,
          central: [],
          count: 0,
          state: :entries,
          on_entry: on_entry,
          time: dos_time,
          date: dos_date
        }
      end,
      &next/1,
      &cleanup/1
    )
  end

  @doc """
  Regroups a stream of iodata into binaries of at least `min_size` bytes
  (except for the last one). S3 multipart uploads require parts of at least 5 MiB.
  """
  def rechunk(stream, min_size) do
    stream
    |> Stream.chunk_while(
      {[], 0},
      fn chunk, {acc, size} ->
        size = size + IO.iodata_length(chunk)
        acc = [acc, chunk]

        if size >= min_size do
          {:cont, IO.iodata_to_binary(acc), {[], 0}}
        else
          {:cont, {acc, size}}
        end
      end,
      fn
        {_acc, 0} -> {:cont, {[], 0}}
        {acc, _size} -> {:cont, IO.iodata_to_binary(acc), {[], 0}}
      end
    )
  end

  ## Stream.resource callbacks

  defp next(%{state: :finished} = s), do: {:halt, s}

  defp next(%{state: :entries, current: nil} = s) do
    case pull(s.entries) do
      {:ok, entry, cont} ->
        s = %{s | entries: cont}
        begin_entry(entry, s)

      :done ->
        finish(s)
    end
  end

  defp next(%{state: :entries, current: current} = s) do
    case pull(current.data) do
      {:ok, chunk, cont} ->
        chunk = IO.iodata_to_binary(chunk)
        compressed = :zlib.deflate(current.z, chunk)

        current = %{
          current
          | data: cont,
            crc: :erlang.crc32(current.crc, chunk),
            size: current.size + byte_size(chunk),
            csize: current.csize + IO.iodata_length(compressed)
        }

        {[compressed], %{s | current: current, offset: s.offset + IO.iodata_length(compressed)}}

      :done ->
        end_entry(s)
    end
  end

  defp cleanup(%{current: %{data: cont, z: z}} = s) do
    :zlib.close(z)
    halt(cont)
    halt(s.entries)
  end

  defp cleanup(s), do: halt(s.entries)

  ## entries

  defp begin_entry(%{data: :dir, path: path} = entry, s) do
    name = String.trim_trailing(path, "/") <> "/"
    header = local_header(name, 0, 20, s)
    record = %{entry: entry, name: name, dir?: true, crc: 0, size: 0, csize: 0, offset: s.offset}
    s = %{s | offset: s.offset + IO.iodata_length(header), central: [record | s.central]}
    s = %{s | count: s.count + 1}
    s.on_entry.(entry)
    {[header], s}
  end

  defp begin_entry(%{data: data, path: path} = entry, s) do
    data = if is_binary(data), do: [data], else: data
    header = local_header(path, @descriptor_flag, 45, s, zip64?: true)
    z = :zlib.open()
    :ok = :zlib.deflateInit(z, :default, :deflated, -15, 8, :default)

    current = %{
      entry: entry,
      name: path,
      data: start(data),
      z: z,
      crc: 0,
      size: 0,
      csize: 0,
      offset: s.offset
    }

    {[header], %{s | current: current, offset: s.offset + IO.iodata_length(header)}}
  end

  defp end_entry(%{current: current} = s) do
    tail = :zlib.deflate(current.z, [], :finish)
    :zlib.close(current.z)
    csize = current.csize + IO.iodata_length(tail)

    descriptor =
      <<0x08074B50::little-32, current.crc::little-32, csize::little-64, current.size::little-64>>

    record = %{
      entry: current.entry,
      name: current.name,
      dir?: false,
      crc: current.crc,
      size: current.size,
      csize: csize,
      offset: current.offset
    }

    out = [tail, descriptor]

    s = %{
      s
      | current: nil,
        offset: s.offset + IO.iodata_length(out),
        central: [record | s.central],
        count: s.count + 1
    }

    s.on_entry.(current.entry)
    {[out], s}
  end

  ## headers

  defp local_header(name, flags, version, s, opts \\ []) do
    zip64? = Keyword.get(opts, :zip64?, false)

    {size_field, extra} =
      if zip64?,
        do: {@max_32, <<1::little-16, 16::little-16, 0::little-64, 0::little-64>>},
        else: {0, <<>>}

    method = if flags == 0, do: 0, else: 8

    [
      <<0x04034B50::little-32, version::little-16, bor(flags, @utf8_flag)::little-16,
        method::little-16, s.time::little-16, s.date::little-16, 0::little-32,
        size_field::little-32, size_field::little-32, byte_size(name)::little-16,
        IO.iodata_length(extra)::little-16>>,
      name,
      extra
    ]
  end

  defp finish(s) do
    central_offset = s.offset
    records = Enum.reverse(s.central)
    central = Enum.map(records, &central_record(&1, s))
    central_size = IO.iodata_length(central)
    eocd = end_of_central_directory(s.count, central_size, central_offset)
    s = %{s | state: :finished}
    {[central, eocd], s}
  end

  defp central_record(r, s) do
    {version, flags, method, ext_attrs} =
      if r.dir?,
        do: {20, 0, 0, bor(0o040755 <<< 16, 0x10)},
        else: {45, @descriptor_flag, 8, 0o100644 <<< 16}

    {size, size_extra} = saturate(r.size)
    {csize, csize_extra} = saturate(r.csize)
    {offset, offset_extra} = saturate(r.offset)

    zip64_data = IO.iodata_to_binary([size_extra, csize_extra, offset_extra])

    extra =
      if zip64_data == <<>>,
        do: <<>>,
        else: <<1::little-16, byte_size(zip64_data)::little-16, zip64_data::binary>>

    [
      <<0x02014B50::little-32, bor(45, 3 <<< 8)::little-16, version::little-16,
        bor(flags, @utf8_flag)::little-16, method::little-16, s.time::little-16,
        s.date::little-16, r.crc::little-32, csize::little-32, size::little-32,
        byte_size(r.name)::little-16, byte_size(extra)::little-16, 0::little-16, 0::little-16,
        0::little-16, ext_attrs::little-32, offset::little-32>>,
      r.name,
      extra
    ]
  end

  defp saturate(value) when value >= @max_32, do: {@max_32, <<value::little-64>>}
  defp saturate(value), do: {value, <<>>}

  defp end_of_central_directory(count, central_size, central_offset) do
    needs_zip64? = count >= @max_16 or central_size >= @max_32 or central_offset >= @max_32

    zip64 =
      if needs_zip64? do
        zip64_eocd_offset = central_offset + central_size

        [
          <<0x06064B50::little-32, 44::little-64, 45::little-16, 45::little-16, 0::little-32,
            0::little-32, count::little-64, count::little-64, central_size::little-64,
            central_offset::little-64>>,
          <<0x07064B50::little-32, 0::little-32, zip64_eocd_offset::little-64, 1::little-32>>
        ]
      else
        []
      end

    [
      zip64,
      <<0x06054B50::little-32, 0::little-16, 0::little-16, min(count, @max_16)::little-16,
        min(count, @max_16)::little-16, min(central_size, @max_32)::little-32,
        min(central_offset, @max_32)::little-32, 0::little-16>>
    ]
  end

  ## helpers

  defp dos_datetime(%NaiveDateTime{} = dt) do
    year = max(dt.year, 1980)

    time = dt.hour <<< 11 ||| dt.minute <<< 5 ||| div(dt.second, 2)
    date = (year - 1980) <<< 9 ||| dt.month <<< 5 ||| dt.day
    {time, date}
  end

  # suspended enumeration, so that entries and data are pulled one at a time
  defp start(enumerable) do
    &Enumerable.reduce(enumerable, &1, fn item, _acc -> {:suspend, item} end)
  end

  defp pull(cont) do
    case cont.({:cont, nil}) do
      {:suspended, item, cont} -> {:ok, item, cont}
      {:done, _} -> :done
      {:halted, _} -> :done
    end
  end

  defp halt(cont) when is_function(cont), do: cont.({:halt, nil})
  defp halt(_), do: :ok
end
