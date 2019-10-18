defmodule RailwayIpc.PersistenceBehaviour do
  @moduledoc false
  alias RailwayIpc.Persistence.ConsumedMessage
  @callback insert_published_message(Map.t(), String.t()) :: tuple()
  @callback insert_consumed_message(Map.t()) :: tuple()
  @callback update_consumed_message(%ConsumedMessage{}, Map.t()) :: tuple()
end
