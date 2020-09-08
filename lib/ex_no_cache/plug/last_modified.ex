defmodule ExNoCache.Plug.LastModified do
  @moduledoc """
  A plug for caching a content using last modify date.

  Requires one option:

    * `:updated_at` - The Module Function Argument tuple to fetch the last
      modify date for the content. The function must return a %DateTime{}
      struct.

  ## Cache mechanisms

  `ExNoCache.Plug.LastModified` uses content last modification datetime to
  determine whether it should set the last-modified in header response or not.

  It first look for the client last modify date from the `"if-modified-since"`
  in the request headers. Then compare with the content last modify date. If the
  datetime is equal, the `ExNoCache.Plug.LastModified` halts the plug and
  returns the `"not modified"` immediately. Otherwise request will just go
  normally and the `"last-modified"` is added in the response headers.

  ## Usage

  Add this plug to the pipeline of the endpoint you want to cache using content
  last update time. Provide the Module Function Argument to get the last updated
  datetime and it should just work.

  Please note that the `ExNoCache.Plug.LastModified` only works with the GET
  request.

  ## Examples

  This plug can be mounted in a `Plug.Builder` pipeline as follows:

      def MyPlug do
        use Plug.Builder

        plug ExNoCache.Plug.LastModified, updated_at: {My, :awesome, ["function"]}
      end

  """
  @moduledoc since: "0.1.0"

  require Logger

  @behaviour Plug

  @control "no-cache, private, max-age: 86400"
  @allowed_method ~w(GET)

  alias Plug.Conn

  @type options :: [updated_at: mfa()]

  @impl Plug
  @doc false
  @spec init(options()) :: options()
  def init(opts) do
    opts
  end

  @impl Plug
  @doc false
  @spec call(Plug.Conn.t(), options()) :: Plug.Conn.t()
  def call(%Conn{method: method} = conn, opts) when method in @allowed_method do
    content_updated_at = get_content_updated_at(opts)
    if_modified_since = Conn.get_req_header(conn, "if-modified-since")

    conn
    |> compare(content_updated_at, if_modified_since)
    |> control(content_updated_at)
  end

  def call(%Conn{} = conn, _) do
    conn
  end

  defp compare(%Conn{} = conn, _content_last_modified_at, []) do
    conn
  end

  defp compare(%Conn{} = conn, nil, _) do
    conn
  end

  defp compare(%Conn{} = conn, content_last_modified_at, [raw_req_last_modified_at | _]) do
    req_last_modified_at = parse_req_last_modified_header(raw_req_last_modified_at)

    case DateTime.compare(content_last_modified_at, req_last_modified_at) do
      :eq ->
        conn
        |> Conn.resp(:not_modified, [])
        |> Conn.halt()

      :gt ->
        conn

      :lt ->
        # FIXME: Not sure how to deal with this. Server downgrades the content?
        conn
    end
  end

  defp control(%Conn{} = conn, nil) do
    conn
    |> Conn.put_resp_header("cache-control", @control)
  end

  defp control(%Conn{} = conn, content_last_modified_at) do
    content_last_modified =
      content_last_modified_at
      |> DateTime.shift_zone!("Etc/UTC")
      |> format_datetime()

    conn
    |> Conn.put_resp_header("cache-control", @control)
    |> Conn.put_resp_header("last-modified", content_last_modified)
  end

  defp get_content_updated_at(opts) do
    case Keyword.get(opts, :updated_at) do
      nil ->
        warn_module_not_set()
        nil

      {mod, fun, args} ->
        case apply(mod, fun, args) do
          {:ok, %DateTime{} = updated_at} ->
            updated_at

          _ ->
            nil
        end
    end
  end

  defp parse_req_last_modified_header(datetime_string) do
    <<
      _weekday::binary-size(3),
      ", ",
      day::binary-size(2),
      " ",
      month::binary-size(3),
      " ",
      year::binary-size(4),
      " ",
      hour::binary-size(2),
      ":",
      minute::binary-size(2),
      ":",
      second::binary-size(2),
      " GMT"
    >> = datetime_string

    {:ok, datetime, _} =
      [
        year,
        "-",
        month_abbr_to_num(month),
        "-",
        day,
        "T",
        hour,
        ":",
        minute,
        ":",
        second,
        "Z"
      ]
      |> IO.iodata_to_binary()
      |> DateTime.from_iso8601()

    datetime
  end

  defp month_abbr_to_num(month_abbr) do
    case month_abbr do
      "Jan" -> "01"
      "Feb" -> "02"
      "Mar" -> "03"
      "Apr" -> "04"
      "May" -> "05"
      "Jun" -> "06"
      "Jul" -> "07"
      "Aug" -> "08"
      "Sep" -> "09"
      "Oct" -> "10"
      "Nov" -> "11"
      "Dec" -> "12"
    end
  end

  defp format_datetime(%DateTime{} = datetime) do
    [
      format_day_of_week(datetime),
      ", ",
      datetime.day |> Integer.to_string() |> String.pad_leading(2, "0"),
      " ",
      format_month(datetime),
      " ",
      datetime.year |> Integer.to_string(),
      " ",
      datetime.hour |> Integer.to_string() |> String.pad_leading(2, "0"),
      ":",
      datetime.minute |> Integer.to_string() |> String.pad_leading(2, "0"),
      ":",
      datetime.second |> Integer.to_string() |> String.pad_leading(2, "0"),
      " GMT"
    ]
    |> IO.iodata_to_binary()
  end

  defp format_day_of_week(%DateTime{} = datetime) do
    case Calendar.ISO.day_of_week(datetime.year, datetime.month, datetime.day) do
      1 -> "Mon"
      2 -> "Tue"
      3 -> "Wed"
      4 -> "Thu"
      5 -> "Fri"
      6 -> "Sat"
      7 -> "Sun"
    end
  end

  defp format_month(%DateTime{} = datetime) do
    case datetime.month do
      1 -> "Jan"
      2 -> "Feb"
      3 -> "Mar"
      4 -> "Apr"
      5 -> "May"
      6 -> "Jun"
      7 -> "Jul"
      8 -> "Aug"
      9 -> "Sep"
      10 -> "Oct"
      11 -> "Nov"
      12 -> "Dec"
    end
  end

  defp warn_module_not_set do
    Logger.warn([
      "[",
      inspect(__MODULE__),
      "] is used but cannot load updated_at. The content updated at check won't work as expected!"
    ])
  end
end
