defmodule RailwayIpc.Test.BatchEventsPublisher do
  use RailwayIpc.Publisher, exchange: "batch:events"

  def emit(message) do
    publish(message)
    :ok
  end
end
