defmodule RailwayIpc.PersistenceBehaviour do
  @moduledoc false
  alias RailwayIpc.Persistence.ConsumedMessage
  @callback insert_consumed_message(Map.t()) :: tuple()
  @callback get_consumed_message(%{uuid: String.t(), queue: String.t()}) :: %ConsumedMessage{}
  @callback lock_message(%{uuid: String.t(), queue: String.t()}) :: Map.t()
  @callback update_consumed_message(%ConsumedMessage{}, Map.t()) :: tuple()
end
