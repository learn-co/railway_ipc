defmodule RailwayIpc.Test.CustomDeadLetterExchangeConsumer do
  use RailwayIpc.EventsConsumer,
    exchange: "experts",
    queue: "are_es_tee",
    arguments: [{"x-dead-letter-exchange", :longstr, "test:errors"}]
end
