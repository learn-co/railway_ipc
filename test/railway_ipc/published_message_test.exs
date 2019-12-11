defmodule RailwayIpc.PublishedMessageTest do
  use ExUnit.Case
  import Mox

  import RailwayIpc.Factory
  use RailwayIpc.DataCase
  alias RailwayIpc.MessagePublishing
  alias RailwayIpc.Core.RoutingInfo
  @tag capture_log: true

  setup do
    RailwayIpc.PersistenceMock
    |> stub_with(RailwayIpc.Persistence)

    :ok
  end

  describe "create/2" do
    setup do
      routing_info = %RoutingInfo{exchange: "exchange"}
      [routing_info: routing_info]
    end

    test "returns the existing message when there is one", %{routing_info: routing_info} do
      existing_message = insert(:published_message)

      protobuf_message = %Events.AThingWasDone{
        uuid: existing_message.uuid,
        user_uuid: existing_message.user_uuid,
        correlation_id: existing_message.correlation_id
      }

      message_publishing = MessagePublishing.new(protobuf_message, routing_info)
      {:ok, persisted_message} = RailwayIpc.PublishedMessage.create(message_publishing)

      assert persisted_message.uuid == existing_message.uuid
    end

    @tag capture_log: true
    test "creates a new message when none exists", %{routing_info: routing_info} do
      protobuf_message = %Events.AThingWasDone{
        uuid: Ecto.UUID.generate(),
        user_uuid: Ecto.UUID.generate(),
        correlation_id: Ecto.UUID.generate()
      }

      message_publishing = MessagePublishing.new(protobuf_message, routing_info)

      {:ok, persisted_message} = RailwayIpc.PublishedMessage.create(message_publishing)

      assert persisted_message.uuid == protobuf_message.uuid
    end
  end
end
