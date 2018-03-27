require Logger

defmodule VizProxy.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    # cowboy server
    dispatch =
      :cowboy_router.compile([
        {"localhost", [
          {"/dyn", VizProxy.HelloHandler, []},
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
    handle(req, state)
  end

  def handle(request, state) do
    Logger.debug(fn -> "In handle" end)
    req = :cowboy_req.reply(
      200,
      %{"content-type" => "text/plain"},
      "Hoakzepokpa ozepfopok",
      request
    )

    {:ok, req, state}
  end
end

defmodule VizProxy.WSHandler do
  @behaviour :cowboy_websocket

  def init(req, state) do
    Logger.debug(fn -> "Init new WS connection" end)
    {:cowboy_websocket, req, state}
  end

  def websocket_init(state) do
    # TODO registering with an atom prevents handling multiple WS connections, maybe use Elixir Registry?
    Process.register(self(), :ws_serve)
    {:ok, state}
  end

  def terminate(reason, _partial_req, _state) do
    Logger.debug(fn -> "terminating WS connection: #{inspect reason}" end)
    :ok
  end

  def websocket_handle({:text, content}, state) do
    {:reply, {:text, "got msg #{content}"}, state}
  end

  def websocket_handle(_frame, state) do
    {:ok, state}
  end

  def websocket_info(info, state) do
    Logger.debug(fn -> "Recved erlang msg: #{inspect info}" end)
    {:reply, {:text, info}, state}
  end
end
