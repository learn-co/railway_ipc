defmodule RailwayIpc.Core.MessageAccessTest do
  import Mox

  use ExUnit.Case
  import Mox
  import RailwayIpc.Factory
  use RailwayIpc.DataCase
  alias RailwayIpc.{MessageConsumption, MessagePublishing}
  alias RailwayIpc.Test.BatchEventsConsumer
  alias RailwayIpc.Core.{EventMessage, Payload, MessageAccess, RoutingInfo}
  @tag capture_log: true

  setup do
    RailwayIpc.PersistenceMock
    |> stub_with(RailwayIpc.Persistence)

    :ok
  end

  describe "persist_published_message/2" do
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
      {:ok, persisted_message} = MessageAccess.persist_published_message(message_publishing)

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

      {:ok, persisted_message} = MessageAccess.persist_published_message(message_publishing)

      assert persisted_message.uuid == protobuf_message.uuid
    end
  end

  describe "persist_consumed_message/1" do
    setup do
      message = %Events.AThingWasDone{
        uuid: Ecto.UUID.generate(),
        user_uuid: Ecto.UUID.generate(),
        correlation_id: Ecto.UUID.generate()
      }

      {:ok, payload} =
        message
        |> Payload.encode()

      exchange = "exchange"
      queue = "queue"

      {:ok, message_consumption} =
        MessageConsumption.new(payload, BatchEventsConsumer, exchange, queue)

      {:ok, event_message} = EventMessage.new(message_consumption)

      message_consumption =
        message_consumption
        |> Map.merge(%{inbound_message: event_message})

      [message_consumption: message_consumption, message: message]
    end

    @tag capture_log: true
    test "returns :ok tuple when no such message exists", %{
      message_consumption: message_consumption,
      message: message
    } do
      {:ok, persisted_message} = MessageAccess.persist_consumed_message(message_consumption)
      assert persisted_message.uuid == message.uuid
    end

    @tag capture_log: true
    test "returns :ok tuple when a message exists in the 'processing' state", %{
      message_consumption: message_consumption,
      message: message
    } do
      insert(:consumed_message, %{uuid: message.uuid, status: "processing"})
      {:ok, persisted_message} = MessageAccess.persist_consumed_message(message_consumption)
      assert persisted_message.uuid == message.uuid
    end

    @tag capture_log: true
    test "returns :ok tuple when a message exists in the 'unknown_message_type' state", %{
      message_consumption: message_consumption,
      message: message
    } do
      insert(:consumed_message, %{uuid: message.uuid, status: "unknown_message_type"})
      {:ok, persisted_message} = MessageAccess.persist_consumed_message(message_consumption)
      assert persisted_message.uuid == message.uuid
    end

    @tag capture_log: true
    test "returns :skip tuple when a message exists in the 'success' state", %{
      message_consumption: message_consumption,
      message: message
    } do
      error_message = "Message with uuid: #{message.uuid} and status: success already exists"
      insert(:consumed_message, %{uuid: message.uuid, status: "success"})
      {:skip, ^error_message} = MessageAccess.persist_consumed_message(message_consumption)
    end

    @tag capture_log: true
    test "returns :skip tuple when a message exists in the 'ignore' state", %{
      message_consumption: message_consumption,
      message: message
    } do
      error_message = "Message with uuid: #{message.uuid} and status: ignore already exists"
      insert(:consumed_message, %{uuid: message.uuid, status: "ignore"})
      {:skip, ^error_message} = MessageAccess.persist_consumed_message(message_consumption)
    end
  end
end
