defmodule RailwayIpc.MessagePublishing do
  alias RailwayIpc.Core.{MessageAccess, RoutingInfo, PublishedMessage}

  defstruct [
    :outbound_message,
    :persisted_message,
    :exchange,
    :queue,
    :error
  ]

  def new(protobuf, %RoutingInfo{exchange: exchange, queue: queue}) do
    outbound_message = PublishedMessage.new(protobuf)
    %__MODULE__{outbound_message: outbound_message, exchange: exchange, queue: queue}
  end

  def process(protobuf, routing_info) do
    new(protobuf, routing_info)
    |> persist_message()
  end

  defp persist_message(message_publishing) do
    case MessageAccess.persist_published_message(message_publishing) do
      {:ok, persisted_message} ->
        update(message_publishing, %{persisted_message: persisted_message})

      {:error, error} ->
        update(message_publishing, %{error: error})
    end
  end

  defp update(message_publishing, attrs) do
    message_publishing
    |> Map.merge(attrs)
  end
end
