defmodule RailwayIpc.PersistenceTest do
  use ExUnit.Case
  use RailwayIpc.DataCase

  alias RailwayIpc.Core.{EventMessage, Payload}
  alias RailwayIpc.{MessageConsumption, Persistence}

  @tag capture_log: true
  describe "insert_consumed_message/1" do
    test "inserts the message record" do
      {:ok, payload, _type} =
        Events.AThingWasDone.new(%{uuid: Ecto.UUID.generate()}) |> Payload.encode()

      {:ok, core_message} = EventMessage.new(%{payload: payload})

      message_consumption = %MessageConsumption{
        exchange: "ipc:batch:events",
        queue: "ironboard:batch:events",
        inbound_message: core_message
      }

      assert {:ok, message} = Persistence.insert_consumed_message(message_consumption)
      assert message.uuid != nil
      assert message.queue == "ironboard:batch:events"
      assert message.exchange == "ipc:batch:events"
      assert message.encoded_message == payload
      assert message.status == "processing"
      assert message.message_type == "Events::AThingWasDone"
    end

    test "it inserts a message with a nil exchange" do
      {:ok, payload, _type} =
        Events.AThingWasDone.new(%{uuid: Ecto.UUID.generate()}) |> Payload.encode()

      {:ok, core_message} = EventMessage.new(%{payload: payload})

      message_consumption = %MessageConsumption{
        queue: "ironboard:batch:events",
        inbound_message: core_message
      }

      assert {:ok, message} = Persistence.insert_consumed_message(message_consumption)
    end
  end
end
