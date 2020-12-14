defmodule RailwayIpc.ConsumedMessageTest do
  use ExUnit.Case
  import Mox

  import RailwayIpc.Factory
  use RailwayIpc.DataCase
  alias RailwayIpc.Core.{EventMessage, Payload}
  alias RailwayIpc.Test.BatchEventsConsumer
  alias RailwayIpc.{ConsumedMessage, MessageConsumption}
  @tag capture_log: true

  setup do
    RailwayIpc.PersistenceMock
    |> stub_with(RailwayIpc.Persistence)

    :ok
  end

  describe "find_or_create/1" do
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
      {:ok, persisted_message} = ConsumedMessage.find_or_create(message_consumption)
      assert persisted_message.uuid == message.uuid
    end

    @tag capture_log: true
    test "returns :ok tuple when a message exists in the 'processing' state", %{
      message_consumption: message_consumption,
      message: message
    } do
      insert(:consumed_message, %{uuid: message.uuid, status: "processing"})
      {:ok, persisted_message} = ConsumedMessage.find_or_create(message_consumption)
      assert persisted_message.uuid == message.uuid
    end

    @tag capture_log: true
    test "returns :ok tuple when a message exists in the 'unknown_message_type' state", %{
      message_consumption: message_consumption,
      message: message
    } do
      insert(:consumed_message, %{uuid: message.uuid, status: "unknown_message_type"})
      {:ok, persisted_message} = ConsumedMessage.find_or_create(message_consumption)
      assert persisted_message.uuid == message.uuid
    end

    @tag capture_log: true
    test "returns :ignore tuple when a message exists in the 'success' state", %{
      message_consumption: message_consumption,
      message: message
    } do
      error_message = "Message with uuid: #{message.uuid} and status: success already exists"
      insert(:consumed_message, %{uuid: message.uuid, status: "success"})
      {:ignore, ^error_message} = ConsumedMessage.find_or_create(message_consumption)
    end

    @tag capture_log: true
    test "returns :ignore tuple when a message exists in the 'ignore' state", %{
      message_consumption: message_consumption,
      message: message
    } do
      error_message = "Message with uuid: #{message.uuid} and status: ignore already exists"
      insert(:consumed_message, %{uuid: message.uuid, status: "ignore"})
      {:ignore, ^error_message} = ConsumedMessage.find_or_create(message_consumption)
    end
  end
end
