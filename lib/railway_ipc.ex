defmodule RailwayIpc do
  alias RailwayIpc.Ipc.RepublishedMessagesPublisher
  @behaviour RailwayIpcBehaviour

  def republish_message(published_message_uuid, request_data) do
    RepublishedMessagesPublisher.invoke_republish_message(published_message_uuid, request_data)
  end
end
