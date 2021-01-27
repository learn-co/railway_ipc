defmodule RailwayIpc.MessageConsumptionBehaviour do
  @moduledoc false
  alias RailwayIpc.Core.EventMessage

  @callback process(String.t(), String.t(), String.t(), String.t(), EventMessage) :: tuple()
end
