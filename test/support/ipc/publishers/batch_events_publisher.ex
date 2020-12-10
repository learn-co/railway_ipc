defmodule RailwayIpc.Test.BatchEventsPublisher do
  @moduledoc false
  use RailwayIpc.Publisher, exchange: "batch:events"

  def emit(message) do
    publish(message)
    :ok
  end
end
