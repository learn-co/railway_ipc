defmodule RailwayIpc.Ipc.Logger do
  require Logger

  def log_republishing_message(message) do
    Logger.info("Republishing message", message_metadata(message))
  end

  def log_consuming_message(message) do
    Logger.info("Consuming message", message_metadata(message))
  end

  def log_message_handled_success(message) do
    Logger.info("Successfully handled message", message_metadata(message))
  end

  def log_message_handled_failure(message, error) do
    metadata = message_metadata(message) ++ [error: error]
    Logger.info("Failed to handle message", metadata)
  end

  defp message_metadata(message) do
    [
      feature: "ipc_republish_message",
      correlation_id: message.correlation_id,
      message_uuid: message.uuid,
      learn_uuid: Map.get(message, :user_uuid, nil),
      event: inspect(message)
    ]
  end
end
