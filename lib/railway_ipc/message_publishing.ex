defmodule RailwayIpc.MessagePublishing do
  @moduledoc false
  alias RailwayIpc.Core.{PublishedMessage, RoutingInfo}
  alias RailwayIpc.PublishedMessage, as: PublishedMessageContext
  @behaviour RailwayIpc.MessagePublishingBehaviour

  defstruct [
    :outbound_message,
    :persisted_message,
    :exchange,
    :queue,
    :error
  ]

  def new(protobuf, %RoutingInfo{exchange: exchange, queue: queue}, format) do
    outbound_message = PublishedMessage.new(protobuf, format)
    %__MODULE__{outbound_message: outbound_message, exchange: exchange, queue: queue}
  end

  def process(protobuf, routing_info, format) do
    new(protobuf, routing_info, format)
    |> persist_message()
  end

  defp persist_message(message_publishing) do
    case PublishedMessageContext.create(message_publishing) do
      {:ok, persisted_message} ->
        {:ok, update(message_publishing, %{persisted_message: persisted_message})}

      {:error, error} ->
        {:error, update(message_publishing, %{error: error})}
    end
  end

  defp update(message_publishing, attrs) do
    message_publishing
    |> Map.merge(attrs)
  end
end
