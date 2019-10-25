defmodule RailwayIpc.PersistenceTest do
  use ExUnit.Case
  use RailwayIpc.DataCase

  alias RailwayIpc.Persistence
  alias RailwayIpc.Core.Payload
  alias RailwayIpc.Core.CommandMessage
  alias RailwayIpc.MessageConsumption
  @tag capture_log: true
  describe "insert_published_message/1" do
    test "inserts the message record" do
      event = Events.AThingWasDone.new()
      exchange = "ipc:batch:commands"
      assert {:ok, message} = Persistence.insert_published_message(event, exchange)
      assert message.exchange == exchange
      assert message.uuid != nil
      assert message.status == "sent"
      assert message.message_type == "Events::AThingWasDone"
    end
  end

  @tag capture_log: true
  describe "insert_consumed_message/1" do
    test "inserts the message record" do
      {:ok, payload} = Events.AThingWasDone.new(%{uuid: Ecto.UUID.generate()}) |> Payload.encode()
      {:ok, core_message} = CommandMessage.new(%{payload: payload})

      message_consumption = %MessageConsumption{
        exchange: "ipc:batch:commands",
        queue: "ironboard:batch:commands",
        inbound_message: core_message
      }

      assert {:ok, message} = Persistence.insert_consumed_message(message_consumption)
      assert message.uuid != nil
      assert message.queue == "ironboard:batch:commands"
      assert message.exchange == "ipc:batch:commands"
      assert message.encoded_message == payload
      assert message.status == "processing"
      assert message.message_type == "Events::AThingWasDone"
    end
  end
end
