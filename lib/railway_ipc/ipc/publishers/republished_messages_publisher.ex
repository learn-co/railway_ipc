defmodule RailwayIpc.Ipc.RepublishedMessagesPublisher do
  use RailwayIpc.Publisher,
    queue: "railway_ipc:republished_messages:commands"

  alias RailwayIpc.Ipc.RepublishedMessageAdapter, as: DataAdapter

  def invoke_republish_message(published_message_uuid, request_data) do
    case DataAdapter.republish_message(published_message_uuid, request_data) do
      {:ok, protobuf} ->
        publish(protobuf)
        :ok

      {:error, _error} = e ->
        e
    end
  end
end
