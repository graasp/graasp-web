defmodule Admin.S3 do
  @moduledoc """
  This module provides functions for interacting with Amazon S3.
  """

  alias Admin.Utils.FileSize
  alias ExAws.S3

  defmodule Bucket do
    @moduledoc """
    Struct to represent a S3 Bucket
    """
    @derive {Phoenix.Param, key: :name}
    defstruct [:name, :creation_date]

    def new(%{name: name, creation_date: creation_date}) do
      %__MODULE__{
        name: name,
        creation_date: creation_date
      }
    end
  end

  defmodule Object do
    @moduledoc """
    Struct to represent a S3 Object
    """
    @derive {Phoenix.Param, key: :key}
    defstruct [:key, :size, :last_modified, :url]

    def new(bucket, %{key: key, size: size, last_modified: last_modified}) do
      %__MODULE__{
        key: key,
        size: FileSize.humanize_size(size |> String.to_integer()),
        last_modified: last_modified,
        url: Admin.S3.get_object_url(bucket, key)
      }
    end
  end

  alias Admin.S3.Bucket
  alias Admin.S3.Object

  # Get the compile-time module providing Ex aws functionality
  @ex_aws_mod Application.compile_env(:admin, [:test_doubles, :ex_aws], ExAws)

  def list_buckets do
    with {:ok, buckets} <- S3.list_buckets() |> @ex_aws_mod.request() do
      buckets.body.buckets |> Enum.map(&Bucket.new/1)
    end
  end

  def list_objects(bucket) do
    {:ok, bucket_objects} =
      S3.list_objects(bucket)
      |> @ex_aws_mod.request()

    %{
      name: bucket_objects.body.name,
      contents: bucket_objects.body.contents |> Enum.map(&Object.new(bucket, &1))
    }
  end

  def get_object_url(bucket, key, opts \\ []) do
    expires_in = Keyword.get(opts, :expires_in, 3600)

    {:ok, url} =
      :s3 |> ExAws.Config.new([]) |> S3.presigned_url(:get, bucket, key, expires_in: expires_in)

    url
  end

  def download(bucket, key) do
    {:ok, body} = S3.get_object(bucket, key) |> @ex_aws_mod.request()
    body.body
  end

  def upload(bucket, key, path) do
    {:ok, _} =
      path
      |> S3.Upload.stream_file()
      |> S3.upload(bucket, key)
      |> @ex_aws_mod.request()
  end

  def upload_stream(stream, bucket, key) do
    {:ok, _} = S3.upload(stream, bucket, key) |> @ex_aws_mod.request()
  end

  def delete_object(bucket, key) do
    {:ok, _} = S3.delete_object(bucket, key) |> @ex_aws_mod.request()
  end

  def delete_objects(bucket, file_paths) when is_list(file_paths) and file_paths != [] do
    # keys can not be longer than 1024 bytes
    key_lengths = file_paths |> Enum.map(&String.length/1) |> Enum.max()

    if key_lengths > 1024 do
      raise "key length must be less than or equal to 1024 bytes, got: #{inspect(file_paths)}"
    end

    {:ok, _} =
      S3.delete_all_objects(bucket, file_paths)
      |> @ex_aws_mod.request()
  end

  def delete_with_prefix(bucket, prefix) when is_binary(prefix) do
    :ok =
      S3.list_objects(bucket, prefix: prefix)
      |> @ex_aws_mod.stream!()
      |> Stream.map(& &1.key)
      # chunk stream so we never get empty batches
      |> Stream.chunk_every(1000)
      |> Stream.each(fn batch ->
        {:ok, _} = S3.delete_all_objects(bucket, batch) |> @ex_aws_mod.request()
      end)
      |> Stream.run()
  end

  def list_folders(bucket, prefix) do
    objects =
      S3.list_objects(bucket, prefix: prefix, delimiter: "/", stream_prefixes: true)
      |> @ex_aws_mod.stream!()

    objects
    |> Stream.map(fn %{prefix: key} ->
      key |> String.trim_leading(prefix) |> String.trim_trailing("/")
    end)
  end

end
