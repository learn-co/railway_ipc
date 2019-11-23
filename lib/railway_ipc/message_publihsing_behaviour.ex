defmodule RailwayIpc.MessagePublishingBehaviour do
  @callback process(message :: Map.t(), routing_info :: Map.t()) :: tuple()
end
