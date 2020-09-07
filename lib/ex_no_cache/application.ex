defmodule ExNoCache.Application do
  @moduledoc false

  use Application

  @doc """
  Starts ExNoCache application.
  """
  @spec start(any, any) :: {:error, any} | {:ok, pid}
  def start(_type, _args) do
    children = [
      {ExNoCache.Cache.GenServer, []}
    ]

    opts = [
      strategy: :one_for_one,
      name: ExNoCache.Supervisor
    ]

    Supervisor.start_link(children, opts)
  end
end
