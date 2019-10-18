defmodule RailwayIpc.MessageConsumptionTest do
  import Mox

  use ExUnit.Case
  import Mox
  import RailwayIpc.Factory

  alias RailwayIpc.MessageConsumption
  alias RailwayIpc.Core.Payload
  alias RailwayIpc.Test.BatchCommandsConsumer
  alias RailwayIpc.Test.OkayConsumer
  alias RailwayIpc.Test.ErrorConsumer
  alias RailwayIpc.Core.CommandMessage
  alias RailwayIpc.Core.EventMessage
  alias RailwayIpc.Persistence.ConsumedMessage

  setup :verify_on_exit!

  describe "process/5 success with a CommandMessage" do
    setup do
      {:ok, payload} =
        Commands.DoAThing.new(correlation_id: "123")
        |> Payload.encode()

      exchange = "commands_exchange"
      queue = "are_es_tee"
      message_module = CommandMessage
      consumed_message = build(:consumed_message)
      attrs = %{status: "handled"}

      updated_message = Map.merge(consumed_message, attrs)

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
        message_module: message_module,
        consumed_message: consumed_message,
        updated_message: updated_message,
        attrs: attrs
      ]
    end

    test "returns an :emit tuple when handler specifies emission", %{
      payload: payload,
      exchange: exchange,
      queue: queue,
      message_module: message_module,
      updated_message: updated_message
    } do
      handle_module = BatchCommandsConsumer

      {:emit, struct} =
        MessageConsumption.process(payload, handle_module, exchange, queue, message_module)

      assert struct.error == nil
      assert struct.persisted_message == updated_message
      assert struct.payload == payload

      %CommandMessage{encoded_message: ^payload, decoded_message: _decoded_message} =
        struct.inbound_message

      %Events.AThingWasDone{} = struct.outbound_message
    end

    test "returns an :ok tuple when handler returns :ok", %{
      payload: payload,
      exchange: exchange,
      queue: queue,
      message_module: message_module,
      updated_message: updated_message
    } do
      handle_module = OkayConsumer

      {:ok, struct} =
        MessageConsumption.process(payload, handle_module, exchange, queue, message_module)

      assert struct.error == nil
      assert struct.persisted_message == updated_message
      assert struct.payload == payload

      %CommandMessage{encoded_message: ^payload, decoded_message: _decoded_message} =
        struct.inbound_message

      assert struct.outbound_message == nil
    end
  end

  describe "process/5 failure with a CommandMessage" do
    setup do
      exchange = "commands_exchange"
      queue = "are_es_tee"
      message_module = CommandMessage
      consumed_message = build(:consumed_message)

      RailwayIpc.PersistenceMock
      |> stub(:insert_consumed_message, fn _message ->
        {:ok, consumed_message}
      end)

      [
        exchange: exchange,
        queue: queue,
        message_module: message_module,
        consumed_message: consumed_message
      ]
    end

    test "returns an error tuple when message type is unknown", %{
      exchange: exchange,
      queue: queue,
      message_module: message_module
    } do
      payload = "{\"encoded_message\":\"\",\"type\":\"Events::SomeUnknownThing\"}"
      handle_module = BatchCommandsConsumer

      {:error, struct} =
        MessageConsumption.process(payload, handle_module, exchange, queue, message_module)

      assert struct.persisted_message == nil
      assert struct.error == "Unknown message type Events::SomeUnknownThing"
    end

    test "returns an error tuple when persistence fails", %{
      exchange: exchange,
      queue: queue,
      message_module: message_module
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
        Commands.DoAThing.new(correlation_id: "123")
        |> Payload.encode()

      handle_module = BatchCommandsConsumer

      {:error, struct} =
        MessageConsumption.process(payload, handle_module, exchange, queue, message_module)

      assert struct.persisted_message == nil
      error = Keyword.fetch!(struct.error, :uuid)
      ^error = {"is not unique", []}
    end

    test "returns an error tuple when the handler returns an error tuple", %{
      exchange: exchange,
      queue: queue,
      message_module: message_module
    } do
      {:ok, payload} =
        Commands.DoAThing.new(correlation_id: "123")
        |> Payload.encode()

      handle_module = ErrorConsumer

      {:error, struct} =
        MessageConsumption.process(payload, handle_module, exchange, queue, message_module)

      assert struct.error == "error message"
    end
  end

  describe "process/5 success with an EventMessage" do
    setup do
      {:ok, payload} =
        Events.AThingWasDone.new(correlation_id: "123")
        |> Payload.encode()

      exchange = "events_exchange"
      queue = "queue"
      message_module = EventMessage
      consumed_message = build(:consumed_message)
      attrs = %{status: "handled"}

      updated_message = Map.merge(consumed_message, attrs)

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
        message_module: message_module,
        consumed_message: consumed_message,
        updated_message: updated_message,
        attrs: attrs
      ]
    end

    test "returns an :ok tuple when handler returns :ok", %{
      payload: payload,
      exchange: exchange,
      queue: queue,
      message_module: message_module,
      updated_message: updated_message
    } do
      handle_module = OkayConsumer

      {:ok, struct} =
        MessageConsumption.process(payload, handle_module, exchange, queue, message_module)

      assert struct.error == nil
      assert struct.persisted_message == updated_message
      assert struct.payload == payload

      %EventMessage{encoded_message: ^payload, decoded_message: _decoded_message} =
        struct.inbound_message

      assert struct.outbound_message == nil
    end
  end

  describe "process/5 failure with an EventMessage" do
    setup do
      exchange = "commands_exchange"
      queue = "are_es_tee"
      message_module = EventMessage
      consumed_message = build(:consumed_message)

      RailwayIpc.PersistenceMock
      |> stub(:insert_consumed_message, fn _message ->
        {:ok, consumed_message}
      end)

      [
        exchange: exchange,
        queue: queue,
        message_module: message_module,
        consumed_message: consumed_message
      ]
    end

    test "returns an error tuple when message type is unknown", %{
      exchange: exchange,
      queue: queue,
      message_module: message_module
    } do
      payload = "{\"encoded_message\":\"\",\"type\":\"Events::SomeUnknownThing\"}"
      handle_module = BatchCommandsConsumer

      {:error, struct} =
        MessageConsumption.process(payload, handle_module, exchange, queue, message_module)

      assert struct.persisted_message == nil
      assert struct.error == "Unknown message type Events::SomeUnknownThing"
    end

    test "returns an error tuple when persistence fails", %{
      exchange: exchange,
      queue: queue,
      message_module: message_module
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

      handle_module = BatchCommandsConsumer

      {:error, struct} =
        MessageConsumption.process(payload, handle_module, exchange, queue, message_module)

      assert struct.persisted_message == nil
      error = Keyword.fetch!(struct.error, :uuid)
      ^error = {"is not unique", []}
    end

    test "returns an error tuple when the handler returns an error tuple", %{
      exchange: exchange,
      queue: queue,
      message_module: message_module
    } do
      {:ok, payload} =
        Events.AThingWasDone.new(correlation_id: "123")
        |> Payload.encode()

      handle_module = ErrorConsumer

      {:error, struct} =
        MessageConsumption.process(payload, handle_module, exchange, queue, message_module)

      assert struct.error == "error message"
    end
  end
end
