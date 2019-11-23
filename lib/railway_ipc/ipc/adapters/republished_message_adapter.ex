defmodule RailwayIpc.Ipc.RepublishedMessageAdapter do
  alias LearnIpc.Commands.RepublishMessage

  def republish_message(published_message_uuid, %{
        correlation_id: correlation_id,
        current_user: %{
          learn_uuid: user_uuid
        }
      }) do
    data = RepublishMessage.Data.new(%{published_message_uuid: published_message_uuid})

    {:ok,
     RepublishMessage.new(%{
       data: data,
       user_uuid: user_uuid,
       correlation_id: correlation_id,
       uuid: Ecto.UUID.generate()
     })}
  end

  def republish_message(published_message_uuid, request_data) do
    {:error,
     "Failed to created protobuf with #{published_message_uuid} and request data: #{
       Jason.encode!(request_data)
     }"}
  end
end
