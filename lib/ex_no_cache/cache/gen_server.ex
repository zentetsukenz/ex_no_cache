defmodule ExNoCache.Cache.GenServer do
  @moduledoc """
  A cache storage using `GenServer` as a backend.

  ## Example

  The storage provides two function `get/1` and `store/2`:

  To store an etag for any path using `store/2`:

      ExNoCache.Cache.GenServer.store("/stair/way/to/heaven", "etag")
      :ok

  Then retrieve it back using `get/1`:

      ExNoCache.Cache.GenServer.get("/stair/way/to/heaven")
      "etag"

  """
  @moduledoc since: "0.1.0"

  use GenServer

  @type path :: binary()
  @type etag :: binary()
  @type state :: %{optional(path()) => etag()}

  @doc false
  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @doc false
  @spec init(any) :: {:ok, state()}
  def init(_args) do
    {:ok, %{}}
  end

  @doc false
  @spec get(path()) :: nil | etag()
  def get(path) do
    GenServer.call(__MODULE__, {:get, path})
  end

  @doc false
  @spec store(path(), etag()) :: :ok
  def store(path, etag) do
    GenServer.cast(__MODULE__, {:store, path, etag})
  end

  def handle_call({:get, path}, _from, storage) do
    {:reply, Map.get(storage, path), storage}
  end

  def handle_cast({:store, path, etag}, storage) do
    {:noreply, Map.merge(storage, %{path => etag})}
  end
end
