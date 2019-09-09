defmodule RailwayIpc.Connection.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def start_link(additional_children) when is_list(additional_children) do
    Supervisor.start_link(__MODULE__, additional_children, name: __MODULE__)
  end

  def start_link(stream_connection_url, additional_children \\ []) do
    Supervisor.start_link(__MODULE__, {stream_connection_url, additional_children}, name: __MODULE__)
  end

  def init({stream_connection_url, additional_children}) do
    children = [
      {RailwayIpc.Connection, [stream_connection_url, name: RailwayIpc.Connection]},
      %{
        id: Supervisor,
        start:
          {Supervisor, :start_link,
          [additional_children, [name: RailwayIpc.Consumer.Supervisor, strategy: :one_for_one]]}
      }
    ]

    Supervisor.init(children, strategy: :rest_for_one)
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
