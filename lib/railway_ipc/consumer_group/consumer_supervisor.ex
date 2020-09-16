defmodule RailwayIpc.ConsumerGroup.ConsumerSupervisor do
  use Supervisor

  def start_link(children) do
    Supervisor.start_link(__MODULE__, children)
  end

  def consumer_pids(supervisor) do
    for {_, pid, _, _} <- Supervisor.which_children(supervisor), do: pid
  end

  def stop_consumers(supervisor) do
    for pid <- consumer_pids(supervisor) do
      GenServer.stop(pid)
    end
  end

  def init(children) do
    Supervisor.init(children, strategy: :one_for_one)
  end
end
