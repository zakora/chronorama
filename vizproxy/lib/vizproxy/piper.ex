require Logger

defmodule VizProxy.Piper do
  use GenServer

  def start_link(opts) do
    Task.start_link(fn -> parse_loop() end)
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def pending_frames() do
    GenServer.call(Piper, :list_all)
  end

  def parse_loop() do
    Logger.debug(fn -> "Starting parse_loop()" end)
    Enum.each IO.stream(:stdio, :line), &GenServer.call(Piper, {:new_frame, &1})
  end

  def init(:ok) do
    # TODO use a queue instead of a list
    {:ok, []}
  end

  def handle_call({:new_frame, data}, _from, frames) do
    Logger.debug(fn -> "got new frame with: #{data}" end)
    Logger.debug(fn -> "pids: #{inspect Registry.lookup(VizProxy.Registry, "ws_connections")}" end)
    data = String.trim data
    Registry.dispatch(VizProxy.Registry, "ws_connections", fn entries ->
      for {pid, _} <- entries, do: send(pid, data)
    end)
    frames = frames ++ [data]
    {:reply, frames, frames}
  end

  def handle_call(:list_all, _from, frames) do
    {:reply, frames, frames}
  end
end
