defmodule RailwayIpc.Test.OkayConsumer do
  @moduledoc false
  use RailwayIpc.EventsConsumer,
    events_exchange: "events_exchange",
    queue: "are_es_tee"

  def handle_in(_payload) do
    :ok
  end
end
