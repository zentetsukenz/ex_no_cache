defmodule ExNoCache.Plug.ContentTest do
  use ExUnit.Case, async: true
  use Plug.Test

  alias ExNoCache.Cache.GenServer, as: Store

  @path "/two/steps/from/hell"
  @content "not so dynamic content"
  @opts ExNoCache.Plug.Content.init(store: Store)

  defmodule PlugBypassTest do
    use Plug.Builder

    plug(ExNoCache.Plug.Content, store: Store)
    plug(:passthrough)

    defp passthrough(conn, _), do: Plug.Conn.send_resp(conn, :ok, "not so dynamic content")
  end

  setup do
    {:ok, pid} = start_supervised({Store, []})

    [pid: pid]
  end

  test "bypasses POST request", %{pid: pid} do
    conn =
      conn(:post, @path)
      |> PlugBypassTest.call(@opts)

    assert 200 == conn.status
    assert @content == conn.resp_body
    assert [] == get_resp_header(conn, "etag")
    assert %{} == :sys.get_state(pid)
  end

  test "bypasses PATCH request", %{pid: pid} do
    conn =
      conn(:patch, @path)
      |> PlugBypassTest.call(@opts)

    assert 200 == conn.status
    assert @content == conn.resp_body
    assert [] == get_resp_header(conn, "etag")
    assert %{} == :sys.get_state(pid)
  end

  test "bypasses DELETE request", %{pid: pid} do
    conn =
      conn(:delete, @path)
      |> PlugBypassTest.call(@opts)

    assert 200 == conn.status
    assert @content == conn.resp_body
    assert [] == get_resp_header(conn, "etag")
    assert %{} == :sys.get_state(pid)
  end

  defp uncache_conn do
    conn(:get, @path)
    |> put_req_header("cache-control", "no-cache")
  end

  defp cache_conn do
    {:ok, etag} = ExNoCache.ETag.generate(@content)

    conn(:get, @path)
    |> put_req_header("cache-control", "max-age=0")
    |> put_req_header("if-none-match", etag)
  end

  test "etags uncached GET response", %{pid: pid} do
    conn =
      uncache_conn()
      |> ExNoCache.Plug.Content.call(ExNoCache.Plug.Content.init(@opts))
      |> send_resp(:ok, @content)

    assert 200 == conn.status
    assert @content == conn.resp_body
    assert [etag] = get_resp_header(conn, "etag")
    assert ExNoCache.ETag.generate(@content) == {:ok, etag}
    assert %{@path => etag} == :sys.get_state(pid)
  end

  test "etags cached GET response", %{pid: pid} do
    conn =
      cache_conn()
      |> ExNoCache.Plug.Content.call(ExNoCache.Plug.Content.init(@opts))
      |> send_resp(:ok, @content)

    assert 304 == conn.status
    assert "" == conn.resp_body
    assert [etag] = get_resp_header(conn, "etag")
    assert ExNoCache.ETag.generate(@content) == {:ok, etag}
    assert %{@path => etag} == :sys.get_state(pid)
  end
end
