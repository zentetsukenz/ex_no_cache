:ok = Supervisor.terminate_child(ExNoCache.Supervisor, ExNoCache.Cache.GenServer)

ExUnit.start()
