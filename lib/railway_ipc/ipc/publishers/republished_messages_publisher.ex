defmodule RailwayIpc.Ipc.RepublishedMessagesPublisher do
  use RailwayIpc.Publisher,
    queue: "railway_ipc:republished_messages:commands"

  alias RailwayIpc.Ipc.RepublishedMessageAdapter, as: DataAdapter
  alias RailwayIpc.Ipc.Logger, as: Logger

  def invoke_republish_message(
        nil,
        %{correlation_id: correlation_id, current_user: %{learn_uuid: learn_uuid}} = request_data
      ) do
    error =
      "Failed to created protobuf with nil UUID and request data: #{Jason.encode!(request_data)}"

    Logger.metadata(
      feature: "ipc_republish_message",
      correlation_id: correlation_id,
      actor_uuid: learn_uuid
    )

    Logger.error(error)

    {:error, error}
  end

  def invoke_republish_message(
        _published_message_uuid,
        %{
          correlation_id: correlation_id,
          current_user: %{
            learn_uuid: nil
          }
        } = request_data
      ) do
    error =
      "Failed to created protobuf with nil current user UUID from request data: #{
        Jason.encode!(request_data)
      }"

    Logger.metadata(
      feature: "ipc_republish_message",
      correlation_id: correlation_id
    )

    Logger.error(error)

    {:error, error}
  end

  def invoke_republish_message(
        _published_message_uuid,
        %{
          correlation_id: nil,
          current_user: %{
            learn_uuid: learn_uuid
          }
        } = request_data
      ) do
    error =
      "Failed to created protobuf with nil correlation ID from request data: #{
        Jason.encode!(request_data)
      }"

    Logger.metadata(
      feature: "ipc_republish_message",
      actor_uuid: learn_uuid
    )

    Logger.error(error)
    {:error, error}
  end

  def invoke_republish_message(
        published_message_uuid,
        %{correlation_id: correlation_id, current_user: %{learn_uuid: learn_uuid}} = request_data
      ) do
    Logger.metadata(
      feature: "railway_ipc_invoke_republish",
      correlation_id: correlation_id,
      actor_uuid: learn_uuid
    )

    case DataAdapter.republish_message(published_message_uuid, request_data) do
      {:ok, protobuf} ->
        Logger.metadata(%{message: protobuf})
        Logger.info("Republishing message")
        direct_publish(protobuf)

      {:error, _error} = e ->
        Logger.error(
          "Failed to republish message with UUID: #{published_message_uuid}. Error: #{inspect(e)}",
          feature: "ipc_republish_message",
          learn_uuid: learn_uuid,
          correlation_id: correlation_id
        )

        e
    end
  end

  def invoke_republish_message(
        published_message_uuid,
        request_data
      ) do
    error =
      "Failed to republish message with UUID: #{published_message_uuid} and request data: #{
        Jason.encode!(request_data)
      }"

    Logger.error(
      error,
      feature: "ipc_republish_message"
    )

    {:error, error}
  end
end
