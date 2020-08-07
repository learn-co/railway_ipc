defmodule RailwayIpc.CommandsConsumerTest do
  use ExUnit.Case
  import Mox
  import RailwayIpc.Factory
  setup :set_mox_global
  setup :verify_on_exit!

  alias RailwayIpc.Test.BatchCommandsConsumer
  alias RailwayIpc.Connection
  alias RailwayIpc.StreamMock
  alias RailwayIpc.Core.Payload

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
            BatchCommandsConsumer => %{
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

  test "acks message when successful" do
    {:ok, command} =
      Commands.DoAThing.new(correlation_id: "123", reply_to: "8675309")
      |> Payload.encode()

    event = Events.AThingWasDone.new(correlation_id: "123", uuid: Ecto.UUID.generate())

    consumer_module = BatchCommandsConsumer
    exchange = "commands_exchange"
    queue = "are_es_tee"
    message_module = RailwayIpc.Core.CommandMessage
    events_exchange = "events_exchange"

    StreamMock
    |> expect(
      :setup_exchange_and_queue,
      fn %{pid: _conn_pid}, ^events_exchange, ^queue ->
        :ok
      end
    )
    |> expect(:consume, fn %AMQP.Channel{}, ^queue, _, _ -> {:ok, "test_tag"} end)
    |> expect(
      :publish,
      fn _channel, ^events_exchange, encoded ->
        {:ok, decoded} = encoded |> Payload.decode()
        event = Map.put(event, :uuid, decoded.uuid)
        assert event == decoded
        :ok
      end
    )
    |> expect(:ack, fn %{pid: _pid}, "tag" -> :ok end)

    {:ok, pid} = start_supervised(BatchCommandsConsumer)

    RailwayIpc.MessageConsumptionMock
    |> expect(:process, fn ^command, ^consumer_module, ^exchange, ^queue, ^message_module ->
      {:emit, %RailwayIpc.MessageConsumption{outbound_message: event}}
    end)

    RailwayIpc.MessagePublishingMock
    |> expect(:process, fn ^event, %{exchange: ^events_exchange, queue: nil} ->
      {:ok, encoded_event} = Payload.encode(event)
      {:ok, %{persisted_message: build(:published_message, %{encoded_message: encoded_event})}}
    end)

    send(pid, {:basic_deliver, command, %{delivery_tag: "tag"}})
    # yey async programming
    Process.sleep(100)
  end

  test "acks message even if there's an issue with the payload" do
    consumer_module = BatchCommandsConsumer
    exchange = "commands_exchange"
    queue = "are_es_tee"
    message_module = RailwayIpc.Core.CommandMessage

    StreamMock
    |> expect(
      :setup_exchange_and_queue,
      fn %{pid: _conn_pid}, _events_exchange, ^queue ->
        :ok
      end
    )
    |> expect(:consume, fn %AMQP.Channel{}, ^queue, _, _ -> {:ok, "test_tag"} end)
    |> expect(:ack, fn %{pid: _pid}, "tag" -> :ok end)

    {:ok, pid} = start_supervised(BatchCommandsConsumer)
    message = "{\"encoded_message\":\"\",\"type\":\"Events::SomeUnknownThing\"}"

    RailwayIpc.MessageConsumptionMock
    |> expect(:process, fn ^message, ^consumer_module, ^exchange, ^queue, ^message_module ->
      {:error, %RailwayIpc.MessageConsumption{result: %{reason: "error message"}}}
    end)

    send(pid, {:basic_deliver, message, %{delivery_tag: "tag"}})
    # yey async programming
    Process.sleep(100)
  end
end
