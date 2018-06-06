require Logger

defmodule VizProxy.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    # cowboy server
    dispatch =
      :cowboy_router.compile([
        {"localhost", [
          {"/ws", VizProxy.WSHandler, []},
          {"/", :cowboy_static, {:priv_file, :vizproxy, "main.html"}},
        ]},
      ])

    {:ok, _} =
      :cowboy.start_clear(
        VizProxy.HelloHandler,
        [{:port, 8899}],
        %{env: %{dispatch: dispatch}}
      )

    children = [
      {Registry, keys: :duplicate, name: VizProxy.Registry},  # NOTE maybe use System.schedulers_online to boost throughput
      {VizProxy.Piper, name: Piper},
    ]

    opts = [strategy: :one_for_one]
    IO.puts("Hello, startin gthe app")
    Supervisor.start_link(children, opts)
  end
end

defmodule VizProxy.HelloHandler do
  def init(req, state) do
    Logger.debug(fn -> "In init" end)
    {:ok, req, state}
  end
end

defmodule VizProxy.WSHandler do
  @behaviour :cowboy_websocket

  def init(req, state) do
    # NOTE any state here is setup temporarily for the WS connection,
    #      after that it is scrapped and the real init takes place in
    #      websocket_init/1
    Logger.debug(fn -> "Init new WS connection" end)
    {:cowboy_websocket, req, state}
  end

  def websocket_init(state) do
    {:ok, _} = Registry.register(VizProxy.Registry, "ws_connections", nil)
    Logger.debug(fn -> "WS init" end)
    Logger.debug(fn -> "pids: #{inspect Registry.lookup(VizProxy.Registry, "ws_connections")}" end)
    {:ok, state}
  end

  def terminate(reason, _partial_req, _state) do
    Logger.debug(fn -> "terminating WS connection: #{inspect reason}" end)
    :ok
  end

  def websocket_handle({:text, content}, state) do
    {:reply, {:text, "forwarding msg #{content}"}, state}
  end

  def websocket_handle(_frame, state) do
    {:ok, state}
  end

  def websocket_info(info, state) do
    Logger.debug(fn -> "Recved erlang msg: #{inspect info}" end)
    {:reply, {:text, info}, state}
  end
end
