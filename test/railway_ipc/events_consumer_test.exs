defmodule RailwayIpc.EventsConsumerTest do
  use ExUnit.Case
  import Mox
  setup :set_mox_global
  setup :verify_on_exit!

  alias RailwayIpc.Test.BatchEventsConsumer
  alias RailwayIpc.Connection
  alias RailwayIpc.PayloadMock
  alias RailwayIpc.StreamMock

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
         fn connection, channels, consumer_module ->
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
    StreamMock
    |> expect(
         :bind_queue,
         fn %{pid: _conn_pid},
            %{
              consumer_module: BatchEventsConsumer,
              consumer_pid: _pid,
              exchange: "experts",
              queue: "are_es_tee"
            } ->
           :ok
         end
       )
    |> expect(:ack, fn %{pid: _pid}, "tag" -> :ok end)

    {:ok, pid} = BatchEventsConsumer.start_link(:ok)
    message = "My Message"

    PayloadMock
    |> expect(:decode, fn ^message -> {:ok, %{message: message}} end)

    send(pid, {:basic_deliver, message, %{delivery_tag: "tag"}})
    # yey async programming
    Process.sleep(100)
  end

  test "acks message even if there's an issue with the payload" do
    StreamMock
    |> expect(
         :bind_queue,
         fn %{pid: _conn_pid} = x,
            %{
              consumer_module: BatchEventsConsumer,
              consumer_pid: _pid,
              exchange: "experts",
              queue: "are_es_tee"
            } ->
           :ok
         end
       )
    |> expect(:ack, fn %{pid: _pid}, "tag" -> :ok end)

    {:ok, pid} = BatchEventsConsumer.start_link(:ok)
    message = "My Message"

    PayloadMock
    |> expect(:decode, fn ^message -> {:error, "Kaboom"} end)

    send(pid, {:basic_deliver, message, %{delivery_tag: "tag"}})
    # yey async programming
    Process.sleep(100)
  end
end
