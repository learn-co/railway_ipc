defmodule RailwayIpc.MessageConsumptionTest do
  import Mox

  use ExUnit.Case
  use RailwayIpc.DataCase

  import Mox
  import RailwayIpc.Factory

  alias RailwayIpc.Core.EventMessage
  alias RailwayIpc.Core.Payload
  alias RailwayIpc.MessageConsumption
  alias RailwayIpc.Persistence.ConsumedMessage
  alias RailwayIpc.Test.BatchEventsConsumer
  alias RailwayIpc.Test.ErrorConsumer
  alias RailwayIpc.Test.OkayConsumer

  setup :verify_on_exit!

  describe "process/5 success with an EventMessage" do
    setup do
      {:ok, payload} =
        Events.AThingWasDone.new(correlation_id: "123")
        |> Payload.encode()

      exchange = "events_exchange"
      queue = "queue"
      consumed_message = build(:consumed_message)
      attrs = %{status: "success"}

      updated_message = Map.merge(consumed_message, attrs)

      RailwayIpc.PersistenceMock
      |> stub(:get_consumed_message, fn %{uuid: _, queue: _} ->
        nil
      end)

      RailwayIpc.PersistenceMock
      |> stub(:lock_message, fn message ->
        message
      end)

      RailwayIpc.PersistenceMock
      |> stub(:insert_consumed_message, fn _message ->
        {:ok, consumed_message}
      end)

      RailwayIpc.PersistenceMock
      |> stub(:update_consumed_message, fn ^consumed_message, ^attrs ->
        {:ok, updated_message}
      end)

      [
        payload: payload,
        exchange: exchange,
        queue: queue,
        consumed_message: consumed_message,
        updated_message: updated_message,
        attrs: attrs
      ]
    end

    test "returns an :ok tuple when handler returns :ok", %{
      payload: payload,
      exchange: exchange,
      queue: queue,
      updated_message: updated_message
    } do
      handle_module = OkayConsumer

      {:ok, struct} = MessageConsumption.process(payload, handle_module, exchange, queue)

      assert struct.result.reason == nil
      assert struct.persisted_message == updated_message
      assert struct.payload == payload

      %EventMessage{encoded_message: ^payload, decoded_message: _decoded_message} =
        struct.inbound_message

      assert struct.outbound_message == nil
    end
  end

  describe "process/5 failure with an EventMessage" do
    setup do
      exchange = "events_exchange"
      queue = "are_es_tee"
      consumed_message = build(:consumed_message)

      RailwayIpc.PersistenceMock
      |> stub(:get_consumed_message, fn %{uuid: _, queue: _} ->
        nil
      end)

      RailwayIpc.PersistenceMock
      |> stub(:lock_message, fn message ->
        message
      end)

      RailwayIpc.PersistenceMock
      |> stub(:insert_consumed_message, fn _message ->
        {:ok, consumed_message}
      end)

      [
        exchange: exchange,
        queue: queue,
        consumed_message: consumed_message
      ]
    end

    test "returns a skip tuple when message type is unknown", %{
      exchange: exchange,
      queue: queue,
      consumed_message: consumed_message
    } do
      RailwayIpc.PersistenceMock
      |> stub(:update_consumed_message, fn _message, %{status: "unknown_message_type"} = attrs ->
        {:ok, Map.merge(consumed_message, attrs)}
      end)

      payload = "{\"encoded_message\":\"\",\"type\":\"Events::SomeUnknownThing\"}"
      handle_module = BatchEventsConsumer

      {:skip, struct} = MessageConsumption.process(payload, handle_module, exchange, queue)

      assert struct.persisted_message != nil
      assert struct.result.reason == "Unknown message of type: Events::SomeUnknownThing"
    end

    test "returns an error tuple when persistence fails", %{
      exchange: exchange,
      queue: queue
    } do
      changeset =
        %ConsumedMessage{}
        |> ConsumedMessage.changeset(%{})
        |> Ecto.Changeset.add_error(:uuid, "is not unique")

      RailwayIpc.PersistenceMock
      |> stub(:insert_consumed_message, fn _message ->
        {:error, changeset}
      end)

      {:ok, payload} =
        Events.AThingWasDone.new(correlation_id: "123")
        |> Payload.encode()

      handle_module = BatchEventsConsumer

      {:error, struct} = MessageConsumption.process(payload, handle_module, exchange, queue)

      assert struct.persisted_message == nil
      error = Keyword.fetch!(struct.result.reason, :uuid)
      ^error = {"is not unique", []}
    end

    test "returns an error tuple when the handler returns an error tuple", %{
      exchange: exchange,
      queue: queue
    } do
      {:ok, payload} =
        Events.AThingWasDone.new(correlation_id: "123")
        |> Payload.encode()

      handle_module = ErrorConsumer

      {:error, struct} = MessageConsumption.process(payload, handle_module, exchange, queue)

      assert struct.result.reason == "error message"
    end
  end

  describe "process/5 idempotency checks" do
    setup do
      exchange = "events_exchange"
      queue = "are_es_tee"
      consumed_message = build(:consumed_message)

      RailwayIpc.PersistenceMock
      |> stub(:lock_message, fn message ->
        message
      end)

      [
        exchange: exchange,
        queue: queue,
        consumed_message: consumed_message
      ]
    end

    test "returns the ok tuple when a message with the status 'processing' exists", %{
      exchange: exchange,
      queue: queue,
      consumed_message: consumed_message
    } do
      {:ok, payload} =
        Events.AThingWasDone.new(correlation_id: "123")
        |> Payload.encode()

      handle_module = OkayConsumer

      RailwayIpc.PersistenceMock
      |> stub(:get_consumed_message, fn %{uuid: _, queue: _} ->
        consumed_message
      end)

      RailwayIpc.PersistenceMock
      |> stub(:update_consumed_message, fn _message, _attrs ->
        {:ok, Map.merge(consumed_message, %{status: "success"})}
      end)

      {:ok, message} = MessageConsumption.process(payload, handle_module, exchange, queue)

      assert message.persisted_message.uuid == consumed_message.uuid
    end

    test "returns the ok tuple when a message with the status 'unknown_message_type' exists", %{
      exchange: exchange,
      queue: queue,
      consumed_message: consumed_message
    } do
      {:ok, payload} =
        Events.AThingWasDone.new(correlation_id: "123")
        |> Payload.encode()

      handle_module = OkayConsumer

      RailwayIpc.PersistenceMock
      |> stub(:get_consumed_message, fn %{uuid: _, queue: _} ->
        consumed_message
      end)

      RailwayIpc.PersistenceMock
      |> stub(:update_consumed_message, fn _message, _attrs ->
        {:ok, Map.merge(consumed_message, %{status: "unknown_message_type"})}
      end)

      {:ok, message} = MessageConsumption.process(payload, handle_module, exchange, queue)

      assert message.persisted_message.uuid == consumed_message.uuid
    end

    test "returns the skip tuple when a message with the status 'success' exists", %{
      exchange: exchange,
      queue: queue,
      consumed_message: consumed_message
    } do
      {:ok, payload} =
        Events.AThingWasDone.new(correlation_id: "123", uuid: consumed_message.uuid)
        |> Payload.encode()

      handle_module = OkayConsumer

      RailwayIpc.PersistenceMock
      |> expect(:get_consumed_message, fn %{uuid: _, queue: _} ->
        Map.merge(consumed_message, %{status: "success"})
      end)

      {:skip, message_consumption} =
        MessageConsumption.process(payload, handle_module, exchange, queue)

      assert message_consumption.result.reason ==
               "Message with uuid: #{consumed_message.uuid} and status: success already exists"
    end

    test "returns the skip tuple when a message with the status 'ignore' exists", %{
      exchange: exchange,
      queue: queue,
      consumed_message: consumed_message
    } do
      {:ok, payload} =
        Events.AThingWasDone.new(correlation_id: "123", uuid: consumed_message.uuid)
        |> Payload.encode()

      handle_module = OkayConsumer

      RailwayIpc.PersistenceMock
      |> stub(:get_consumed_message, fn %{uuid: _, queue: _} ->
        Map.merge(consumed_message, %{status: "ignore"})
      end)

      RailwayIpc.PersistenceMock
      |> stub(:update_consumed_message, fn _message, %{status: "ignore"} = attrs ->
        {:ok, Map.merge(consumed_message, attrs)}
      end)

      {:skip, message_consumption} =
        MessageConsumption.process(payload, handle_module, exchange, queue)

      assert message_consumption.result.status == :ignore

      assert message_consumption.result.reason ==
               "Message with uuid: #{consumed_message.uuid} and status: ignore already exists"
    end
  end
end
