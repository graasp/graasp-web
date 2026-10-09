defmodule Admin.FolderExports.ZipStreamTest do
  use ExUnit.Case, async: true

  import Admin.FolderExportsFixtures, only: [unzip: 1]

  alias Admin.FolderExports.ZipStream

  test "encodes binaries, streams and directories into a valid zip" do
    big = :crypto.strong_rand_bytes(300_000)

    entries = [
      %{path: "a/hello.txt", data: "hello"},
      %{path: "a/empty", data: :dir},
      %{
        path: "a/big.bin",
        data:
          big
          |> :binary.bin_to_list()
          |> Enum.chunk_every(100_000)
          |> Stream.map(&:erlang.list_to_binary/1)
      },
      %{path: "a/empty.txt", data: ""}
    ]

    bytes = entries |> ZipStream.encode() |> Enum.into(<<>>, &IO.iodata_to_binary/1)

    assert %{
             "a/hello.txt" => "hello",
             "a/empty/" => nil,
             "a/big.bin" => ^big,
             "a/empty.txt" => ""
           } = unzip(bytes)
  end

  test "an empty archive is a valid zip" do
    bytes = [] |> ZipStream.encode() |> Enum.into(<<>>, &IO.iodata_to_binary/1)
    assert unzip(bytes) == %{}
  end

  test "calls on_entry once an entry is written" do
    test_pid = self()

    [%{path: "a", data: "1"}, %{path: "b", data: "2"}]
    |> ZipStream.encode(on_entry: fn entry -> send(test_pid, {:written, entry.path}) end)
    |> Stream.run()

    assert_received {:written, "a"}
    assert_received {:written, "b"}
  end

  test "rechunk emits parts of at least the given size, except the last" do
    chunks = ZipStream.rechunk(["aaa", "bb", "cccc", "d"], 5) |> Enum.to_list()
    assert chunks == ["aaabb", "ccccd"]

    assert ZipStream.rechunk(["aaa", "bb", "ccc"], 5) |> Enum.to_list() == ["aaabb", "ccc"]
    assert ZipStream.rechunk([], 5) |> Enum.to_list() == []
  end
end
