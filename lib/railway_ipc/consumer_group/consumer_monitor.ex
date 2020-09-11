defmodule RailwayIpc.ConsumerGroup.ConsumerMonitor do
  use GenServer, restart: :transient
  alias RailwayIpc.ConsumerGroup.Supervisor, as: CGSupervisor

  def start_link(supervisor) do
    GenServer.start_link(__MODULE__, supervisor)
  end

  def init(supervisor) do
    {:ok, %{supervisor: supervisor}, {:continue, :monitor}}
  end

  def handle_continue(:monitor, %{supervisor: supervisor} = state) do
    for pid <- CGSupervisor.consumer_pids(supervisor) do
      Process.monitor(pid)
    end

    {:noreply, state}
  end

  def handle_info(
        {:DOWN, _ref, :process, _pid, _reason},
        %{supervisor: supervisor} = state
      ) do
    CGSupervisor.stop_consumers(supervisor)
    {:stop, :normal, state}
  end
end
