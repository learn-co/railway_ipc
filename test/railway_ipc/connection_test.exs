defmodule RailwayIpc.ConnectionTest do
  use ExUnit.Case
  import Mox
  setup :set_mox_global
  setup :verify_on_exit!

  alias RailwayIpc.Connection
  alias RailwayIpc.StreamMock

  test "consumes exchange and queue" do
    channel = %{pid: self()}
    connection = %{pid: self()}

    spec = %{
      exchange: "experts",
      queue: "are_es",
      consumer_pid: self(),
      consumer_module: AModule
    }

    StreamMock
    |> expect(
      :connect,
      fn ->
        {
          :ok,
          connection
        }
      end
    )
    |> expect(
      :get_channel_from_cache,
      fn ^connection, %{}, AModule ->
        {:ok, %{channel: channel}, channel}
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
    channel = %{pid: self()}
    connection = %{pid: self()}
    spec = %{exchange: "experts", queue: "are_es", consumer_pid: self(), consumer_module: AModule}

    StreamMock
    |> expect(
      :connect,
      fn ->
        {:ok, connection}
      end
    )
    |> expect(
      :get_channel_from_cache,
      fn ^connection, %{}, AModule ->
        {:ok, %{channel: channel}, channel}
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
