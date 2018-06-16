require Logger

defmodule VizProxy.Piper do
  use GenServer

  def start_link(opts) do
    {:ok, task_pid} = Task.start_link(fn -> parse_loop() end)
    GenServer.start_link(__MODULE__, task_pid, opts)
  end

  def parse_loop() do
    Logger.debug(fn -> "Starting parse_loop()" end)
    Enum.each(IO.stream(:stdio, :line), fn line ->
      case get_status() do
        :streaming ->
          send_frame(line)

        :paused ->
          receive do
            :ready ->
              send_frame(line)
            msg ->
              Logger.warn(fn -> "Received unexpected message: #{inspect msg}" end)
          end
      end
    end)
  end

  defp send_frame(line) do
    # Basic data clean up
    data = String.trim(line)

    # Send the data to each registered WS connection
    Registry.dispatch(VizProxy.Registry, "ws_connections", fn entries ->
      for {pid, _} <- entries, do: send(pid, data)
    end)
  end

  def get_status() do
    {status, _task_pid} = GenServer.call(VizProxy.Piper, :state)
    status
  end

  def set_streaming(), do: GenServer.call(VizProxy.Piper, :ready)
  def set_paused(), do: GenServer.call(VizProxy.Piper, :pause)


  # CALLBACKS

  @impl true
  def init(task_pid) do
    {:ok, {:paused, task_pid}}
  end

  @impl true
  def handle_call(:ready, _from, {_status, task_pid}) do
    send(task_pid, :ready)
    {:reply, :ok, {:streaming, task_pid}}
  end

  @impl true
  def handle_call(:pause, _from, {_status, task_pid}) do
    {:reply, :ok, {:paused, task_pid}}
  end

  @impl true
  def handle_call(:state ,_from, state) do
    {:reply, state, state}
  end
end
