defmodule RailwayIpcBehaviour do
  alias RailwayIpc.Core.{EventMessage, CommandMessage}
  @callback process_published_message(message :: Map.t(), routing_info :: Map.t()) :: tuple()
  @callback process_consumed_message(String.t(), String.t(), String.t(), String.t(), EventMessage) ::
              tuple()
  @callback process_consumed_message(
              String.t(),
              String.t(),
              String.t(),
              String.t(),
              CommandMessage
            ) :: tuple()
end
