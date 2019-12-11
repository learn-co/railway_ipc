defmodule RailwayIpcBehaviour do
  @callback republish_message(published_message_uuid :: String.t(), request_data :: Map.t()) ::
              atom()
end
