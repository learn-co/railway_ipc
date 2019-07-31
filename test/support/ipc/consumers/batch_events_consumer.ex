defmodule RailwayIpc.Test.BatchEventsConsumer do
  use RailwayIpc.EventsConsumer, exchange: "experts", queue: "are_es_tee"
end
