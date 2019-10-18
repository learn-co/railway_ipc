defmodule RailwayIpc.Test.ErrorConsumer do
  use RailwayIpc.CommandsConsumer,
    commands_exchange: "commands_exchange",
    events_exchange: "events_exchange",
    queue: "are_es_tee"

  def handle_in(_payload) do
    {:error, "error message"}
  end
end
