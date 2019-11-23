defmodule RailwayIpcBehaviour do
  alias RailwayIpc.Core.{EventMessage, CommandMessage}
  @callback process_published_message(Map.t(), String.t(), String.t()) :: tuple()
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
