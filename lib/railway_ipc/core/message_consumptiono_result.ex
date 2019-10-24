defmodule RailwayIpc.Core.MessageConsumptionResult do
  defstruct [:status, :reason]

  def new({status, reason}) do
    %__MODULE__{status: status, reason: reason}
  end

  def new(%{status: status}) do
    %__MODULE__{status: status}
  end
end
