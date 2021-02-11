defmodule RailwayIpc.RequestsConsumerTest do
  use ExUnit.Case
  import Mox
  setup :set_mox_global
  setup :verify_on_exit!

  alias RailwayIpc.Connection
  alias RailwayIpc.Core.Payload
  alias RailwayIpc.StreamMock
  alias RailwayIpc.Test.BatchRequestsConsumer

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
            BatchRequestsConsumer => %{
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
    {:ok, pid} = BatchRequestsConsumer.start_link(:ok)
    found_pid = Process.whereis(BatchRequestsConsumer)
    assert found_pid == pid
  end

  test "acks message when successful" do
    {:ok, request, _type} =
      Requests.RequestAThing.new(correlation_id: "123", reply_to: "8675309") |> Payload.encode()

    response = Responses.RequestedThing.new(correlation_id: "123")

    StreamMock
    |> expect(
      :bind_queue,
      fn %{pid: _conn_pid},
         %{
           consumer_module: BatchRequestsConsumer,
           consumer_pid: _pid,
           exchange: "experts",
           queue: "are_es_tee"
         } ->
        :ok
      end
    )
    |> expect(
      :direct_publish,
      fn _channel, "8675309", encoded ->
        {:ok, decoded} = encoded |> Payload.decode()
        response = Map.put(response, :uuid, decoded.uuid)
        assert response == decoded
        :ok
      end
    )
    |> expect(:ack, fn %{pid: _pid}, "tag" -> :ok end)

    {:ok, pid} = BatchRequestsConsumer.start_link(:ok)

    send(pid, {:basic_deliver, request, %{delivery_tag: "tag"}})
    # yey async programming
    Process.sleep(100)
  end

  test "acks message even if there's an issue with the payload" do
    StreamMock
    |> expect(
      :bind_queue,
      fn %{pid: _conn_pid},
         %{
           consumer_module: BatchRequestsConsumer,
           consumer_pid: _pid,
           exchange: "experts",
           queue: "are_es_tee"
         } ->
        :ok
      end
    )
    |> expect(:ack, fn %{pid: _pid}, "tag" -> :ok end)

    {:ok, pid} = BatchRequestsConsumer.start_link(:ok)
    message = "{\"encoded_message\":\"\",\"type\":\"Events::SomeUnknownThing\"}"

    send(pid, {:basic_deliver, message, %{delivery_tag: "tag"}})
    # yey async programming
    Process.sleep(100)
  end
end
