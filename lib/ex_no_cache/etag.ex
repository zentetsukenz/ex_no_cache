defmodule ExNoCache.ETag do
  @moduledoc """
  An etag generator.
  """
  @moduledoc since: "0.1.0"

  @doc """
  Generate ETag.

  Returns `{:ok, binary}`.
  """
  @spec generate(iodata()) :: {:ok, binary()}
  def generate(term) when is_binary(term) or is_list(term) do
    etag =
      :sha256
      |> :crypto.hash(term)
      |> Base.encode16(case: :lower)

    {:ok, etag}
  end
end
