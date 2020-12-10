defmodule RailwayIpc.PersistenceBehaviour do
  @moduledoc false
  alias RailwayIpc.Persistence.{ConsumedMessage, PublishedMessage}
  @moduledoc false
  alias RailwayIpc.Persistence.ConsumedMessage
  @callback insert_published_message(Map.t()) :: tuple()
  @callback insert_consumed_message(Map.t()) :: tuple()
  @callback get_consumed_message(%{uuid: String.t(), queue: String.t()}) :: %ConsumedMessage{}
  @callback get_published_message(String.t()) :: %PublishedMessage{}
  @callback lock_message(%{uuid: String.t(), queue: String.t()}) :: Map.t()
  @callback update_consumed_message(%ConsumedMessage{}, Map.t()) :: tuple()
end
