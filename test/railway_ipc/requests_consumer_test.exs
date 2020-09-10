defmodule RailwayIpc.RequestsConsumerTest do
  use ExUnit.Case
  import Mox
  setup :set_mox_global
  setup :verify_on_exit!

  alias RailwayIpc.Test.BatchRequestsConsumer
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
            BatchRequestsConsumer => %{
              pid: self()
            }
          },
          %{pid: self()}
        }
      end
    )

    :ok
  end

  test "starts and names process" do
    {:ok, pid} = start_supervised(BatchRequestsConsumer)
    found_pid = Process.whereis(BatchRequestsConsumer)
    assert found_pid == pid
  end

  test "acks message when successful" do
    exchange = "experts"
    queue = "are_es_tee"

    {:ok, request} =
      Requests.RequestAThing.new(correlation_id: "123", reply_to: "8675309") |> Payload.encode()

    response = Responses.RequestedThing.new(correlation_id: "123")

    StreamMock
    |> expect(
      :setup_exchange_and_queue,
      fn %{pid: _conn_pid}, ^exchange, ^queue ->
        :ok
      end
    )
    |> expect(:consume, fn %AMQP.Channel{}, ^queue, _, _ -> {:ok, "test_tag"} end)
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

    {:ok, pid} = start_supervised(BatchRequestsConsumer)

    send(pid, {:basic_deliver, request, %{delivery_tag: "tag"}})
    # yey async programming
    Process.sleep(100)
  end

  test "acks message even if there's an issue with the payload" do
    exchange = "experts"
    queue = "are_es_tee"

    StreamMock
    |> expect(
      :setup_exchange_and_queue,
      fn %{pid: _conn_pid}, ^exchange, ^queue ->
        :ok
      end
    )
    |> expect(:consume, fn %AMQP.Channel{}, ^queue, _, _ -> {:ok, "test_tag"} end)
    |> expect(:ack, fn %{pid: _pid}, "tag" -> :ok end)

    {:ok, pid} = start_supervised(BatchRequestsConsumer)
    message = "{\"encoded_message\":\"\",\"type\":\"Events::SomeUnknownThing\"}"

    send(pid, {:basic_deliver, message, %{delivery_tag: "tag"}})
    # yey async programming
    Process.sleep(100)
  end
end
