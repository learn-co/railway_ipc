defmodule RailwayIpc.Ipc.RepublishedMessagesPublisherTest do
  use ExUnit.Case
  import Mox
  import RailwayIpc.Factory
  setup :set_mox_global
  setup :verify_on_exit!

  alias RailwayIpc.Core.{Payload, RoutingInfo}
  alias RailwayIpc.Ipc.RepublishedMessagesPublisher
  alias RailwayIpc.{Connection, MessagePublishing, StreamMock}
  @queue "railway_ipc:republished_messages:commands"

  setup do
    StreamMock
    |> stub(
      :connect,
      fn ->
        {:ok, %{pid: self()}}
      end
    )
    |> stub(
      :get_channel,
      fn _conn ->
        {:ok, %{pid: self()}}
      end
    )
    |> stub(
      :get_channel_from_cache,
      fn _connection, _channels, _consumer_module ->
        {
          :ok,
          %{
            BatchEventsPublisher => %{
              pid: self()
            }
          },
          %{pid: self()}
        }
      end
    )

    Connection.start_link(name: Connection)

    StreamMock
    |> stub(
      :direct_publish,
      fn _channel, _exchange, message ->
        {:ok, _decoded} = Payload.decode(message)
      end
    )

    request_data = %{
      current_user: %{learn_uuid: Ecto.UUID.generate()},
      correlation_id: Ecto.UUID.generate()
    }

    original_published_message_uuid = Ecto.UUID.generate()
    [request_data: request_data, original_published_message_uuid: original_published_message_uuid]
  end

  @tag capture_log: true
  describe "invoke_republish_message/2" do
    test "persists a published message", %{
      request_data: request_data,
      original_published_message_uuid: original_published_message_uuid
    } do
      # credo:disable-for-lines:2 Credo.Check.Design.AliasUsage
      command =
        RailwayIpc.Commands.RepublishMessage.new(user_uuid: "abcabc", uuid: Ecto.UUID.generate())

      persisted_published_message =
        build(:published_message, %{
          uuid: command.uuid,
          message_type: "RailwayIpc::Commands::RepublishMessage",
          encoded_message:
            "{\"encoded_message\":\"\",\"type\":\"RailwayIpc::Commands::RepublishMessage\"}"
        })

      RailwayIpc.MessagePublishingMock
      |> stub_with(RailwayIpc.MessagePublishing)

      RailwayIpc.PersistenceMock
      |> expect(:insert_published_message, fn %MessagePublishing{queue: @queue} ->
        {:ok, persisted_published_message}
      end)

      RepublishedMessagesPublisher.invoke_republish_message(
        original_published_message_uuid,
        request_data
      )
    end

    test "publishes the message directly to the republish queue", %{
      request_data: request_data,
      original_published_message_uuid: original_published_message_uuid
    } do
      # credo:disable-for-lines:2 Credo.Check.Design.AliasUsage
      command =
        RailwayIpc.Commands.RepublishMessage.new(user_uuid: "abcabc", uuid: Ecto.UUID.generate())

      persisted_published_message =
        build(:published_message, %{
          uuid: command.uuid,
          message_type: "RailwayIpc::Commands::RepublishMessage",
          encoded_message:
            "{\"encoded_message\":\"\",\"type\":\"RailwayIpc::Commands::RepublishMessage\"}"
        })

      RailwayIpc.MessagePublishingMock
      |> expect(:process, fn _message, %RoutingInfo{queue: @queue} ->
        {:ok, %{persisted_message: persisted_published_message}}
      end)

      StreamMock
      |> expect(
        :direct_publish,
        fn _channel, _exchange, message ->
          {:ok, _decoded} = Payload.decode(message)
        end
      )

      RepublishedMessagesPublisher.invoke_republish_message(
        original_published_message_uuid,
        request_data
      )
    end

    test "it returns an error tuple when failure to direct publish the message", %{
      request_data: request_data,
      original_published_message_uuid: original_published_message_uuid
    } do
      RailwayIpc.MessagePublishingMock
      |> expect(:process, fn _message, %RoutingInfo{queue: @queue} ->
        {:error, %{error: "Failed to persist message"}}
      end)

      {:error, "Failed to persist message"} =
        RepublishedMessagesPublisher.invoke_republish_message(
          original_published_message_uuid,
          request_data
        )
    end
  end
end
