defmodule RailwayIpc.Connection.Supervisor do
  @moduledoc false
  use Supervisor
  alias RailwayIpc.Telemetry

  def start_link(additional_children \\ []) do
    Supervisor.start_link(__MODULE__, additional_children, name: __MODULE__)
  end

  def init(additional_children) do
    Telemetry.track_application_start(
      %{consumers: additional_children},
      fn ->
        children = [
          {RailwayIpc.Connection, name: RailwayIpc.Connection},
          {RailwayIpc.Publisher, name: RailwayIpc.Publisher},
          %{
            id: Supervisor,
            start:
              {Supervisor, :start_link,
               [
                 additional_children,
                 [name: RailwayIpc.Consumer.Supervisor, strategy: :one_for_one]
               ]}
          }
        ]

        {Supervisor.init(children, strategy: :rest_for_one), %{}}
      end
    )
  end
end
