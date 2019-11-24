defmodule RailwayIpc.Ipc.RepublishedMessagesConsumer do
  use RailwayIpc.CommandsConsumer,
    queue: "railway_ipc:republished_messages:commands",
    publish_function: &RailwayIpc.Publisher.publish/1

  alias RailwayIpc.Ipc.Logger
  alias LearnIpc.Commands.RepublishMessage
  alias RailwayIpc.PublishedMessage

  def handle_in(
        %RepublishMessage{data: %{published_message_uuid: published_message_uuid}} = message
      ) do
    case PublishedMessage.get(published_message_uuid) do
      nil ->
        Logger.log_message_handled_failure(
          message,
          "Unable to find published message with UUID: #{published_message_uuid}"
        )

        :ok

      %{message_type: "LearnIpc::Commands::RepublishMessage"} ->
        {:error, "Cannot republish message of type: LearnIpc::Commands::RepublishMessage"}
      %{exchange: nil} ->
        {:error, "Cannot republish message to exchange: nil"}
      published_message ->
        {:emit, published_message}
    end
  end
end
