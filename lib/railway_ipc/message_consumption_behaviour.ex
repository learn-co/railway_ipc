defmodule RailwayIpc.MessageConsumptionBehaviour do
  @moduledoc false

  @callback process(String.t(), String.t(), String.t(), String.t(), String.t()) :: tuple()
end
