defmodule RailwayIpc.PublisherTest do
  use ExUnit.Case
  import Mox
  import RailwayIpc.Factory
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

  test "persists the message with a status of 'sent'" do
    user_uuid = Ecto.UUID.generate()
    correlation_id = Ecto.UUID.generate()
    exchange = "commands:a_thing"

    message =
      Commands.DoAThing.new(%{
        user_uuid: user_uuid,
        correlation_id: correlation_id,
        uuid: Ecto.UUID.generate()
      })

    {:ok, encoded_message} = Payload.encode(message)

    RailwayIpcMock
    |> expect(:process_published_message, fn ^message, ^exchange ->
      {:ok, build(:published_message, %{encoded_message: encoded_message})}
    end)

    RailwayIpc.Publisher.publish("channel", exchange, message)
  end
end
