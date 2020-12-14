defmodule RailwayIpc.MessageConsumptionBehaviour do
  @moduledoc false
  alias RailwayIpc.Core.{CommandMessage, EventMessage}

  @callback process(String.t(), String.t(), String.t(), String.t(), EventMessage) ::
              tuple()
  @callback process(
              String.t(),
              String.t(),
              String.t(),
              String.t(),
              CommandMessage
            ) :: tuple()
end
