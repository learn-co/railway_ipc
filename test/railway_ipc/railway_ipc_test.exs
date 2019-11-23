defmodule RailwayIpcTest do
  import Mox
  use RailwayIpc.DataCase

  use ExUnit.Case
  import Mox
  import RailwayIpc.Factory

  alias RailwayIpc.{StreamMock, Connection, MessagePublishing, Persistence}

  setup :set_mox_global
  setup :verify_on_exit!

  @tag capture_log: true
  describe "republish_message/2" do
    setup do
      RailwayIpc.MessagePublishingMock
      |> stub_with(MessagePublishing)

      RailwayIpc.PersistenceMock
      |> stub_with(Persistence)

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
      :ok
    end

    test "publishes the LearnIpc.Commands.RepublishMessage protobuf for the given persisted message" do
      message =
        Events.AThingWasDone.new(%{user_uuid: Ecto.UUID.generate(), uuid: Ecto.UUID.generate()})

      request_data = %{
        current_user: %{learn_uuid: Ecto.UUID.generate()},
        correlation_id: Ecto.UUID.generate()
      }

      published_message_record = insert(:published_message, %{uuid: message.uuid})

      StreamMock
      |> expect(
        :direct_publish,
        fn _channel, _queue, _encoded_message ->
          {:ok, message}
        end
      )

      :ok = RailwayIpc.republish_message(published_message_record.uuid, request_data)
    end

    test "returns an error tuple when the message cannot be published" do
      request_data = %{
        current_user: %{learn_uuid: Ecto.UUID.generate()},
        correlation_id: Ecto.UUID.generate()
      }

      {:error, _message} = RailwayIpc.republish_message(nil, request_data)
    end
  end
end
