defmodule ExNoCache.Plug.LastModifiedTest do
  use ExUnit.Case, async: true
  use Plug.Test

  defmodule MockLastModifyMod do
    def get do
      {:ok, datetime, _} = DateTime.from_iso8601("2020-09-07T20:00:00Z")

      {:ok, datetime}
    end
  end

  @path "/two/steps/from/hell"
  @content "expect me"
  @last_modified_header "Mon, 07 Sep 2020 20:00:00 GMT"
  @opts ExNoCache.Plug.LastModified.init(updated_at: {MockLastModifyMod, :get, []})

  defmodule PlugBypassTest do
    use Plug.Builder

    plug(ExNoCache.Plug.LastModified, updated_at: {MockLastModifyMod, :get, []})
    plug(:passthrough)

    defp passthrough(conn, _), do: Plug.Conn.send_resp(conn, :ok, "expect me")
  end

  test "bypasses POST request" do
    conn =
      conn(:post, @path)
      |> PlugBypassTest.call(@opts)

    assert 200 == conn.status
    assert @content == conn.resp_body
    assert [] == get_resp_header(conn, "last-modified")
  end

  test "bypasses PATCH request" do
    conn =
      conn(:post, @path)
      |> PlugBypassTest.call(@opts)

    assert 200 == conn.status
    assert @content == conn.resp_body
    assert [] == get_resp_header(conn, "last-modified")
  end

  test "bypasses DELETE request" do
    conn =
      conn(:post, @path)
      |> PlugBypassTest.call(@opts)

    assert 200 == conn.status
    assert @content == conn.resp_body
    assert [] == get_resp_header(conn, "last-modified")
  end

  defp uncache_conn do
    conn(:get, @path)
    |> put_req_header("cache-control", "no-cache")
  end

  defp cache_conn(if_modified_since) do
    conn(:get, @path)
    |> put_req_header("cache-control", "max-age=0")
    |> put_req_header("if-modified-since", if_modified_since)
  end

  test "adds last modified to uncached conn" do
    conn =
      uncache_conn()
      |> ExNoCache.Plug.LastModified.call(@opts)
      |> send_resp(:ok, @content)

    assert 200 == conn.status
    assert @content == conn.resp_body
    assert [last_modified] = get_resp_header(conn, "last-modified")
    assert @last_modified_header == last_modified
    assert [cache_control] = get_resp_header(conn, "cache-control")
    assert "no-cache, private, max-age: 86400" == cache_control
  end

  test "updates last modified to cached conn" do
    conn =
      cache_conn("Mon, 06 Sep 2020 20:00:00 GMT")
      |> ExNoCache.Plug.LastModified.call(@opts)
      |> send_resp(:ok, @content)

    assert 200 == conn.status
    assert @content == conn.resp_body
    assert [last_modified] = get_resp_header(conn, "last-modified")
    assert @last_modified_header == last_modified
    assert [cache_control] = get_resp_header(conn, "cache-control")
    assert "no-cache, private, max-age: 86400" == cache_control
  end

  test "unmodifies response" do
    conn =
      cache_conn(@last_modified_header)
      |> ExNoCache.Plug.LastModified.call(@opts)

    assert 304 == conn.status
    assert conn.halted
    assert [] == conn.resp_body
    assert [last_modified] = get_resp_header(conn, "last-modified")
    assert @last_modified_header == last_modified
    assert [cache_control] = get_resp_header(conn, "cache-control")
    assert "no-cache, private, max-age: 86400" == cache_control
  end
end
