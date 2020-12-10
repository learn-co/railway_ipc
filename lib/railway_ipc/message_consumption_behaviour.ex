defmodule RailwayIpc.MessageConsumptionBehaviour do
  @moduledoc false
  alias RailwayIpc.Core.{EventMessage, CommandMessage}

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
