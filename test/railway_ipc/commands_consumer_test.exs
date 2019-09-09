defmodule RailwayIpc.CommandsConsumerTest do
  use ExUnit.Case
  import Mox
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

  test "starts and names process" do
    {:ok, pid} = BatchCommandsConsumer.start_link(:ok)
    found_pid = Process.whereis(BatchCommandsConsumer)
    assert found_pid == pid
  end

  test "acks message when successful" do
    {:ok, command} =
      Commands.DoAThing.new(correlation_id: "123", reply_to: "8675309")
      |> Payload.encode()

    event = Events.AThingWasDone.new(correlation_id: "123")

    StreamMock
    |> expect(
      :bind_queue,
      fn %{pid: _conn_pid},
         %{
           consumer_module: BatchCommandsConsumer,
           consumer_pid: _pid,
           exchange: "commands_exchange",
           queue: "are_es_tee"
         } ->
        :ok
      end
    )
    |> expect(
      :publish,
      fn _channel, "events_exchange", encoded ->
        {:ok, decoded} = encoded |> Payload.decode()
        event = Map.put(event, :uuid, decoded.uuid)
        assert event == decoded
        :ok
      end
    )
    |> expect(:ack, fn %{pid: _pid}, "tag" -> :ok end)

    {:ok, pid} = BatchCommandsConsumer.start_link(:ok)

    send(pid, {:basic_deliver, command, %{delivery_tag: "tag"}})
    # yey async programming
    Process.sleep(100)
  end

  test "acks message even if there's an issue with the payload" do
    StreamMock
    |> expect(
      :bind_queue,
      fn %{pid: _conn_pid},
         %{
           consumer_module: BatchCommandsConsumer,
           consumer_pid: _pid,
           exchange: "commands_exchange",
           queue: "are_es_tee"
         } ->
        :ok
      end
    )
    |> expect(:ack, fn %{pid: _pid}, "tag" -> :ok end)

    {:ok, pid} = BatchCommandsConsumer.start_link(:ok)
    message = "{\"encoded_message\":\"\",\"type\":\"Events::SomeUnknownThing\"}"

    send(pid, {:basic_deliver, message, %{delivery_tag: "tag"}})
    # yey async programming
    Process.sleep(100)
  end
end
