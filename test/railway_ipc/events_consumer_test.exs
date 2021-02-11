defmodule RailwayIpc.EventsConsumerTest do
  use ExUnit.Case
  import Mox
  setup :set_mox_global
  setup :verify_on_exit!

  alias RailwayIpc.Connection
  alias RailwayIpc.Core.Payload
  alias RailwayIpc.MessageConsumption
  alias RailwayIpc.StreamMock
  alias RailwayIpc.Test.BatchEventsConsumer

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
            BatchEventsConsumer => %{
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

  test "starts and names process" do
    {:ok, pid} = BatchEventsConsumer.start_link(:ok)
    found_pid = Process.whereis(BatchEventsConsumer)
    assert found_pid == pid
  end

  test "acks message when successful" do
    consumer_module = BatchEventsConsumer
    exchange = "experts"
    queue = "are_es_tee"

    StreamMock
    |> expect(
      :bind_queue,
      fn %{pid: _conn_pid},
         %{
           consumer_module: ^consumer_module,
           consumer_pid: _pid,
           exchange: ^exchange,
           queue: ^queue
         } ->
        :ok
      end
    )
    |> expect(:ack, fn %{pid: _pid}, "tag" -> :ok end)

    {:ok, pid} = BatchEventsConsumer.start_link(:ok)
    {:ok, message, _type} = Events.AThingWasDone.new() |> Payload.encode()

    RailwayIpc.MessageConsumptionMock
    |> expect(:process, fn ^message, ^consumer_module, ^exchange, ^queue, nil ->
      {:ok,
       %MessageConsumption{
         inbound_message: %{
           decoded_message: %Events.AThingWasDone{}
         }
       }}
    end)

    send(pid, {:basic_deliver, message, %{delivery_tag: "tag"}})
    # yey async programming
    Process.sleep(100)
  end

  test "acks message even if there's an issue with the payload" do
    consumer_module = BatchEventsConsumer
    exchange = "experts"
    queue = "are_es_tee"

    StreamMock
    |> expect(
      :bind_queue,
      fn %{pid: _conn_pid},
         %{
           consumer_module: ^consumer_module,
           consumer_pid: _pid,
           exchange: ^exchange,
           queue: ^queue
         } ->
        :ok
      end
    )
    |> expect(:ack, fn %{pid: _pid}, "tag" -> :ok end)

    {:ok, pid} = BatchEventsConsumer.start_link(:ok)
    message = "{\"encoded_message\":\"\",\"type\":\"Events::SomeUnknownThing\"}"

    RailwayIpc.MessageConsumptionMock
    |> expect(:process, fn ^message, ^consumer_module, ^exchange, ^queue, nil ->
      {:ok,
       %MessageConsumption{
         inbound_message: %{
           decoded_message: %Events.AThingWasDone{}
         }
       }}
    end)

    send(pid, {:basic_deliver, message, %{delivery_tag: "tag"}})
    # yey async programming
    Process.sleep(100)
  end
end
