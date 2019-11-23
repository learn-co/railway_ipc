defmodule RailwayIpc.Ipc.RepublishedMessagesPublisher do
  use RailwayIpc.Publisher, queue: "railway_ipc:republished_messages:commands"

  def publish_test do
    message = Commands.DoAThing.new(%{
      user_uuid: Ecto.UUID.generate(),
      correlation_id: Ecto.UUID.generate(),
      uuid: Ecto.UUID.generate()
    })
    publish(message)
  end

  def invoke_republish_message(_persisted_published_message_uuid) do
    # create Commands.RepublishMessage struct with persisted_published_message_uuid
    # publish(that_struct)
  end
end
