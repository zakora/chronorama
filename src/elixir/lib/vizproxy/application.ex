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
          {"/static/[...]", :cowboy_static, {:priv_dir, :vizproxy, "static"}},
        ]},
      ])

    {:ok, _} =
      :cowboy.start_clear(
        VizProxy.WSServer,
        [{:port, 8899}],
        %{env: %{dispatch: dispatch}}
      )

    children = [
      {Registry, keys: :duplicate, name: VizProxy.Registry},  # NOTE maybe use System.schedulers_online to boost throughput
      {VizProxy.Piper, name: VizProxy.Piper},
    ]

    opts = [strategy: :one_for_one]
    IO.puts("Starting the app")
    Supervisor.start_link(children, opts)
  end
end

defmodule VizProxy.WSHandler do
  @behaviour :cowboy_websocket

  def init(req, state) do
    # NOTE any state here is setup temporarily for the HTTP connection to be
    # upgraded to a WebSocket connection. After that, it is scrapped and the
    # real init takes place in websocket_init/1.
    Logger.debug(fn -> "Init new WS connection" end)
    {:cowboy_websocket, req, state}
  end

  def websocket_init(_state) do
    {:ok, _} = Registry.register(VizProxy.Registry, "ws_connections", nil)
    Logger.debug(fn -> "WS init" end)
    Logger.debug(fn -> "pids: #{inspect Registry.lookup(VizProxy.Registry, "ws_connections")}" end)
    {:ok, :paused}
  end

  def terminate(reason, _partial_req, _state) do
    Logger.debug(fn -> "terminating WS connection: #{inspect reason}" end)
    :ok
  end

  def websocket_handle({:text, content}, state) do
    # Callback called for every text WS frame received.
    Logger.debug(fn -> "Received WS text frame: #{content}" end)

    case content do
      "PAUSE" ->
        VizProxy.Piper.set_paused()
      "READY" ->
        VizProxy.Piper.set_streaming()
    end

    Logger.debug(fn -> "Current state: #{inspect state}" end)
    {:ok, state}
  end

  def websocket_handle(frame, state) do
    # Callback called for every non-text WS frame received.
    Logger.debug(fn -> "Received WS frame: #{frame}" end)
    {:ok, state}
  end

  def websocket_info(info, state) do
    # Callback called for every erlang message received.
    Logger.debug(fn -> "Received erlang msg: #{inspect info}. Forwarding to WS client." end)
    {:reply, {:text, info}, state}
  end
end
