defmodule RailwayIpc.Core.MessageConsumptionResult do
  @moduledoc false
  defstruct [:status, :reason]

  def new({status, reason}) do
    %__MODULE__{status: status, reason: reason}
  end

  def new(attrs) do
    %__MODULE__{
      status: attrs[:status],
      reason: attrs[:reason]
    }
  end
end
