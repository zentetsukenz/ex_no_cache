defmodule ExNoCache.Cache.GenServerTest do
  use ExUnit.Case, async: true

  alias ExNoCache.Cache.GenServer, as: Store

  setup do
    {:ok, _pid} = start_supervised({Store, []})
    :ok
  end

  test "stores path and etag" do
    assert :ok == Store.store("/path", "etag")
    assert "etag" == Store.get("/path")
  end
end
