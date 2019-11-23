defmodule RailwayIpc.Ipc.RepublishedMessagesConsumer do
  use RailwayIpc.CommandsConsumer,
    queue: "railway_ipc:republished_messages:commands"

  alias RailwayIpc.Publisher
  alias RailwayIpc.Ipc.Logger
  alias LearnIpc.Commands.RepublishMessage
  @persistence Application.get_env(:railway_ipc, :persistence, RailwayIpc.Persistence)

  def handle_in(%RepublishMessage{data: %{published_message_uuid: published_message_uuid}} = message) do
    case @persistence.get_published_message(published_message_uuid) do
      nil ->
        Logger.log_message_handled_failure(
          message,
          "Unable to find published message with UUID: #{published_message_uuid}"
        )

        :ok

      published_message ->
        republish_message(message, published_message)
        :ok
    end
  end

  def republish_message(consumed_message, published_message) do
    case Publisher.publish(published_message) do
      :ok ->
        Logger.log_message_handled_success(consumed_message)
      error ->
        Logger.log_message_handled_failure(
          consumed_message,
          "Failed to re-publish message with UUID: #{published_message.uuid}, error: #{error}"
        )
    end
  end
end
