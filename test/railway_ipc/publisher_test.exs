defmodule RailwayIpc.PublisherTest do
  use ExUnit.Case
  import Mox
  setup :set_mox_global
  setup :verify_on_exit!

  alias RailwayIpc.StreamMock
  alias RailwayIpc.Connection
  alias RailwayIpc.Core.Payload
  alias RailwayIpc.Test.BatchEventsPublisher

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
            BatchEventsPublisher => %{
              pid: self()
            }
          },
          %{pid: self()}
        }
      end
    )

    Connection.start_link(name: Connection)

    StreamMock
    |> stub(
      :publish,
      fn _channel, _exchange, message ->
        {:ok, _decoded} = Payload.decode(message)
      end
    )

    :ok
  end

  test "adds uuid to published message" do
    command = Events.AThingWasDone.new(user_uuid: "abcabc")

    with message <- RailwayIpc.Publisher.prepare_message(command),
         {:ok, decoded} <- Payload.decode(message) do
      assert {:ok, _} = UUID.info(decoded.uuid)
    end
  end
end
