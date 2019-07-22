defmodule LearnIpcEx.ConsumerTest do
  use ExUnit.Case
  import Mox
  setup :set_mox_global
  setup :verify_on_exit!

  alias LearnIpcEx.Test.BatchConsumer
  alias LearnIpcEx.Connection
  alias LearnIpcEx.PayloadMock
  alias LearnIpcEx.StreamMock

  setup do
    StreamMock
    |> stub(
         :connect,
         fn ->
           {
             :ok,
             %{
               connection: %{
                 pid: self()
               },
               channel: "Channel Info"
             }
           }
         end
       )
    Connection.start_link(name: Connection)
    :ok
  end

  test "starts and names process" do
    {:ok, pid} = BatchConsumer.start_link(:ok)
    found_pid = Process.whereis(BatchConsumer)
    assert found_pid == pid
  end

  test "acks message when successful" do
    StreamMock
    |> expect(
         :bind_queue,
         fn "Channel Info", %{consumer: _pid, exchange: "experts", queue: "are_es_tee"} ->
           :ok
         end
       )
    |> expect(:ack, fn "Channel Info", "tag" -> :ok end)

    {:ok, pid} = BatchConsumer.start_link(:ok)
    message = "My Message"

    PayloadMock
    |> expect(:decode, fn ^message -> {:ok, %{message: message}} end)

    send pid, {:basic_deliver, message, %{delivery_tag: "tag"}}
    Process.sleep(100) # yey async programming
  end
  test "acks message even if there's an issue with the payload" do
    StreamMock
    |> expect(
         :bind_queue,
         fn "Channel Info", %{consumer: _pid, exchange: "experts", queue: "are_es_tee"} ->
           :ok
         end
       )
    |> expect(:ack, fn "Channel Info", "tag" -> :ok end)

    {:ok, pid} = BatchConsumer.start_link(:ok)
    message = "My Message"

    PayloadMock
    |> expect(:decode, fn ^message -> {:error, "Kaboom"} end)

    send pid, {:basic_deliver, message, %{delivery_tag: "tag"}}
    Process.sleep(100) # yey async programming
  end
end
