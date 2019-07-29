defmodule RailwayIpc.Connection.Supervisor do
  use Supervisor

  def start_link(additional_children \\ []) do
    Supervisor.start_link(__MODULE__, additional_children, name: __MODULE__)
  end

  def init(additional_children) do
    children = [
      {RailwayIpc.Connection, name: RailwayIpc.Connection},
      %{
        id: Supervisor,
        start:
          {Supervisor, :start_link,
           [additional_children, [name: RailwayIpc.Consumer.Supervisor, strategy: :one_for_one]]}
      }
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end
end
