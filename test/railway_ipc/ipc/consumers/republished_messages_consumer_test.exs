defmodule RailwayIpc.Ipc.RebublishedMessagesConsumerTest do
  use ExUnit.Case
  import Mox
  import RailwayIpc.Factory
  use RailwayIpc.DataCase
  setup :verify_on_exit!

  alias RailwayIpc.Ipc.RepublishedMessagesConsumer

  describe "handle_in/1" do
    setup do
      persisted_message = build(:published_message)
      uuid = persisted_message.uuid
      data = RailwayIpc.Commands.RepublishMessage.Data.new(published_message_uuid: uuid)
      command = RailwayIpc.Commands.RepublishMessage.new(data: data)
      [persisted_message: persisted_message, uuid: uuid, command: command]
    end

    test "it returns the emit tuple when it can find the given persisted published message", %{
      persisted_message: persisted_message,
      uuid: uuid,
      command: command
    } do
      RailwayIpc.PersistenceMock
      |> stub(:get_published_message, fn ^uuid ->
        persisted_message
      end)

      {:emit, ^persisted_message} = RepublishedMessagesConsumer.handle_in(command)
    end

    test "it returns an error tuple when the persisted published message is not found", %{
      uuid: uuid,
      command: command
    } do
      RailwayIpc.PersistenceMock
      |> stub(:get_published_message, fn _uuid ->
        nil
      end)

      error_message = "Unable to find published message with UUID: #{uuid}"
      {:error, ^error_message} = RepublishedMessagesConsumer.handle_in(command)
    end

    test "it returns and error tuple when the persisted published message has a nil exchange", %{
      persisted_message: persisted_message,
      command: command
    } do
      RailwayIpc.PersistenceMock
      |> stub(:get_published_message, fn _uuid ->
        Map.merge(persisted_message, %{exchange: nil})
      end)

      error_message = "Cannot republish message to exchange: nil"
      {:error, ^error_message} = RepublishedMessagesConsumer.handle_in(command)
    end

    test "it returns an error tuple when the persisted published message is a RailwayIpc.Commands.RepublishMessage type",
         %{command: command, persisted_message: persisted_message} do
      RailwayIpc.PersistenceMock
      |> stub(:get_published_message, fn _uuid ->
        Map.merge(persisted_message, %{message_type: "RailwayIpc::Commands::RepublishMessage"})
      end)

      error_message = "Cannot republish message of type: RailwayIpc::Commands::RepublishMessage"
      {:error, ^error_message} = RepublishedMessagesConsumer.handle_in(command)
    end

    test "it returns an error tuple when the persisted published message UUID is invalid" do
      uuid = "12345"
      data = RailwayIpc.Commands.RepublishMessage.Data.new(published_message_uuid: uuid)
      command = RailwayIpc.Commands.RepublishMessage.new(data: data)

      RailwayIpc.PersistenceMock
      |> stub(:get_published_message, fn ^uuid ->
        RailwayIpc.Persistence.get_published_message(uuid)
      end)

      error_message = "Invalid message uuid: #{uuid}"
      {:error, ^error_message} = RepublishedMessagesConsumer.handle_in(command)
    end
  end
end
