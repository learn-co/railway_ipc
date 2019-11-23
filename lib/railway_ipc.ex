defmodule RailwayIpc do
  alias RailwayIpc.{MessageConsumption, MessagePublishing}
  alias RailwayIpc.Ipc.RepublishedMessagesPublisher
  @behaviour RailwayIpcBehaviour

  def process_published_message(message, exchange, queue) do
    MessagePublishing.process(message, exchange, queue)
  end

  def process_consumed_message(payload, handle_module, exchange, queue, message_module) do
    MessageConsumption.process(payload, handle_module, exchange, queue, message_module)
  end

  def republish_message(published_message_uuid, request_data) do
    RepublishedMessagesPublisher.invoke_republish_message(published_message_uuid, request_data)
  end
end
