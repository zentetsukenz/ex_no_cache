defmodule ExNoCache.Plug.Content do
  @moduledoc """
  A plug for caching a mid to long term dynamic content.

  Requires one option:

    * `:store` - The storage module used to store etag per path. See
      `ExNoCache.Cache.GenServer` for more detail.

  ## Cache mechanisms

  `ExNoCache.Plug.Content` uses etag for HTTP caching. This means a client
  should cache the response on the first request and validate the cache on
  following requests. The cache-control for etag uses `"private"` mode meaning
  that the content will be kept in the client browser only.

  `ExNoCache.Plug.Content` generate etag using sha256 digest from the response
  body upon running. It stores the generated etag in `ExNoCache.Cache.GenServer`
  as a map of request path and etag.

  ## Usage

  Using `ExNoCache.Plug.Content` is very simple, just plug it into any GET
  request path you want to cache and be done with it.

  Please be aware that the `ExNoCache.Plug.Content` works only with GET method.
  It should be used only with a static path that can generate a dynamic
  content but the content is rarely change.

  `ExNoCache.Plug.Content` should be used as a last resort only when you cannot
  determined the last updated time of the content. Otherwise use
  `ExNoCache.Plug.Time` should be better in terms of efficiency since
  `ExNoCache.Plug.Content` always allows the request to be processed first
  before determining the cache-control strategy.

  ## Examples

  This plug can be mounted in a `Plug.Builder` pipeline as follows:

      def MyPlug do
        use Plug.Builder

        plug ExNoCache.Plug.Content, store: ExNoCache.Cache.GenServer
      end

  """
  @moduledoc since: "0.1.0"

  @behaviour Plug

  @control "no-cache, private, max-age: 86400"
  @allowed_method ~w(GET)

  alias ExNoCache.ETag
  alias Plug.Conn

  @type options :: [store: module()]

  @impl Plug
  @doc false
  @spec init(options()) :: options()
  def init(opts) do
    opts
    |> Keyword.put_new(:store, ExNoCache.Cache.GenServer)
  end

  @impl Plug
  @doc false
  @spec call(Plug.Conn.t(), options()) :: Plug.Conn.t()
  def call(%Conn{method: method} = conn, opts) when method in @allowed_method do
    Plug.Conn.register_before_send(conn, fn conn -> cache_control(conn, opts) end)
  end

  def call(%Conn{} = conn, _opts) do
    conn
  end

  defp cache_control(%Conn{request_path: request_path, resp_body: resp_body} = conn, opts) do
    cache_module = Keyword.get(opts, :store)

    {:ok, etag} = ETag.generate(resp_body)
    cached_etag = get_etag(cache_module, request_path)
    etag_req_headers = Conn.get_req_header(conn, "if-none-match")

    conn
    |> cache(etag, cached_etag, cache_module)
    |> control(etag, etag_req_headers)
  end

  defp cache(%Conn{} = conn, resp_etag, cache_etag, _) when resp_etag == cache_etag, do: conn

  defp cache(%Conn{request_path: request_path} = conn, resp_etag, _, cache_module) do
    store_etag(cache_module, request_path, resp_etag)
    conn
  end

  defp control(%Conn{} = conn, resp_etag, [req_etag | _]) when resp_etag == req_etag do
    conn
    |> Conn.resp(:not_modified, [])
    |> do_control(resp_etag)
  end

  defp control(%Conn{} = conn, resp_etag, _etag_req_headers), do: do_control(conn, resp_etag)

  defp do_control(%Conn{} = conn, etag) do
    conn
    |> Conn.put_resp_header("cache-control", @control)
    |> Conn.put_resp_header("etag", etag)
  end

  defp get_etag(module, path) do
    apply(module, :get, [path])
  end

  defp store_etag(module, path, etag) do
    apply(module, :store, [path, etag])
  end
end
