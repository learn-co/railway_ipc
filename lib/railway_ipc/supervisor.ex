defmodule RailwayIpc.Connection.Supervisor do
  use Supervisor

  def start_link(additional_children \\ []) do
    Supervisor.start_link(__MODULE__, additional_children, name: __MODULE__)
  end

  def init(additional_children) do
    children = [
                 {RailwayIpc.Connection, name: RailwayIpc.Connection}
               ] ++ additional_children
    Supervisor.init(children, strategy: :rest_for_one)
  end
end
