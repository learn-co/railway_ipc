defmodule RailwayIpc do
  alias RailwayIpc.{MessageConsumption, MessagePublishing}
  alias RailwayIpc.{PublishedMessage, ConsumedMessage}
  alias RailwayIpc.Ipc.RepublishedMessagesPublisher
  @behaviour RailwayIpcBehaviour

  def process_published_message(message, routing_info) do
    MessagePublishing.process(message, routing_info)
  end

  def process_consumed_message(payload, handle_module, exchange, queue, message_module) do
    MessageConsumption.process(payload, handle_module, exchange, queue, message_module)
  end

  def republish_message(published_message_uuid, request_data) do
    RepublishedMessagesPublisher.invoke_republish_message(published_message_uuid, request_data)
  end

  def persist_published_message(message_publishing) do
    PublishedMessage.create(message_publishing)
  end

  def persist_consumed_message(message_consumption) do
    ConsumedMessage.create(message_consumption)
  end

  def consumed_message_success(consumed_message) do
    ConsumedMessage.consumed_message_success(consumed_message)
  end
end
