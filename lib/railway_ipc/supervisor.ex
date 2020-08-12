defmodule RailwayIpc.Supervisor do
  use Supervisor

  def start_link(consumers \\ []) do
    Supervisor.start_link(__MODULE__, consumers, name: __MODULE__)
  end

  def init(consumers) do
    children = [
      {RailwayIpc.Connection, name: RailwayIpc.Connection},
      %{
        id: Supervisor,
        start:
          {Supervisor, :start_link,
           [
             [RailwayIpc.Ipc.RepublishedMessagesConsumer | additional_children],
             [name: RailwayIpc.Consumer.Supervisor, strategy: :one_for_one]
           ]}
      }
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end
end
