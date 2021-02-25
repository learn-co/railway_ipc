defmodule RailwayIpc.MessagePublishingBehaviour do
  @moduledoc false
  @callback process(message :: Map.t(), routing_info :: Map.t(), format :: String.t()) :: tuple()
end
