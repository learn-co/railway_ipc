defmodule RailwayIpc.ConnectionTest do
  use ExUnit.Case
  import Mox
  setup :set_mox_global
  setup :verify_on_exit!

  alias RailwayIpc.Connection
  alias RailwayIpc.StreamMock

  test "Connects to stream correctly" do
    channel = %{name: "some channel"}
    StreamMock
    |> expect(
         :connect,
         fn ->
           {
             :ok,
             %{
               connection: %{
                 pid: self()
               },
               channel: channel
             }
           }
         end
       )

    {:ok, pid} = Connection.start_link()
    assert Connection.channel(pid) == channel
  end

  test "consumes exchange and queue" do
    channel = %{name: "some channel"}
    spec = %{exchange: "experts", queue: "are_es", consumer: self()}
    StreamMock
    |> expect(
         :connect,
         fn ->
           {
             :ok,
             %{
               connection: %{
                 pid: self()
               },
               channel: channel
             }
           }
         end
       )
    |> expect(
         :bind_queue,
         fn ^channel, ^spec ->
           :ok
         end
       )

    {:ok, pid} = Connection.start_link()
    {:ok, returned_channel} = Connection.consume(pid, spec)
    assert returned_channel == channel
  end
  test "returns error if consume request fails" do
    channel = %{name: "some channel"}
    spec = %{exchange: "experts", queue: "are_es", consumer: self()}
    StreamMock
    |> expect(
         :connect,
         fn ->
           {
             :ok,
             %{
               connection: %{
                 pid: self()
               },
               channel: channel
             }
           }
         end
       )
    |> expect(
         :bind_queue,
         fn ^channel, ^spec ->
           {:error, "Something Asploded"}
         end
       )

    {:ok, pid} = Connection.start_link()
    {:error, reason} = Connection.consume(pid, spec)
    assert reason == "Something Asploded"
  end
end
