defmodule RailwayIpc.ConsumerGroup.Supervisor do
  use Supervisor

  def start_link(children: children, name: name) when is_atom(name) do
    Supervisor.start_link(__MODULE__, children, name: name)
  end

  def setup_group(children: children, name: name) when is_atom(name) do
    Supervisor.child_spec({__MODULE__, [children: children, name: name]}, id: name)
  end

  def consumer_supervisor(pid) do
    Supervisor.which_children(pid)
    |> Enum.find_value(fn {module, child_pid, _, _} ->
      case module do
        RailwayIpc.ConsumerGroup.ConsumerSupervisor -> child_pid
        _ -> nil
      end
    end)
  end

  def restart_tree(pid) do
    pid
    |> consumer_supervisor
    |> Supervisor.stop()
  end

  def consumer_pids(pid) do
    pid
    |> consumer_supervisor
    |> RailwayIpc.ConsumerGroup.ConsumerSupervisor.consumer_pids()
  end

  def stop_consumers(pid) do
    pid
    |> consumer_supervisor
    |> RailwayIpc.ConsumerGroup.ConsumerSupervisor.stop_consumers()
  end

  @impl true
  def init(children) do
    children = [
      {RailwayIpc.ConsumerGroup.ConsumerSupervisor, children},
      {RailwayIpc.ConsumerGroup.ConsumerMonitor, self()}
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end
end
