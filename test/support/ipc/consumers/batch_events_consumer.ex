defmodule RailwayIpc.Test.BatchEventsConsumer do
  @moduledoc false
  use RailwayIpc.EventsConsumer, exchange: "experts", queue: "are_es_tee"
end
