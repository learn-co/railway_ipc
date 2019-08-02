defmodule RailwayIpc.Test.BatchRequestsConsumer do
  use RailwayIpc.RequestsConsumer,
    exchange: "experts",
    queue: "are_es_tee"

  def handle_in(_payload) do
    {:reply, Responses.RequestedThing.new()}
  end
end