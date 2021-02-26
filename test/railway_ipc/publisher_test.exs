defmodule RailwayIpc.PublisherTest do
  use ExUnit.Case
  import Mox
  import RailwayIpc.Factory
  setup :set_mox_global
  setup :verify_on_exit!

  alias RailwayIpc.Core.Payload
  alias RailwayIpc.Test.BatchEventsPublisher
  alias RailwayIpc.{Connection, MessagePublishing, StreamMock}

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
      fn _channel, _exchange, message, format ->
        {:ok, _decoded, _type} = Payload.decode(message, format)
      end
    )

    :ok
  end

  describe "publish" do
    test "persists the message with a status of 'sent'" do
      user_uuid = Ecto.UUID.generate()
      correlation_id = Ecto.UUID.generate()
      exchange = "events:a_thing"

      message =
        Events.AThingWasDone.new(%{
          user_uuid: user_uuid,
          correlation_id: correlation_id,
          uuid: Ecto.UUID.generate()
        })

      {:ok, encoded_message, _type} = Payload.encode(message, "json_protobuf")

      RailwayIpc.MessagePublishingMock
      |> expect(:process, fn ^message, %{exchange: ^exchange, queue: nil}, _ ->
        {:ok,
         %MessagePublishing{
           persisted_message: build(:published_message, %{encoded_message: encoded_message})
         }}
      end)

      RailwayIpc.Publisher.publish("channel", exchange, message, "json_protobuf")
    end

    test "it returns :ok on publish sucess" do
      user_uuid = Ecto.UUID.generate()
      correlation_id = Ecto.UUID.generate()
      exchange = "events:a_thing"

      message =
        Events.AThingWasDone.new(%{
          user_uuid: user_uuid,
          correlation_id: correlation_id,
          uuid: Ecto.UUID.generate()
        })

      {:ok, encoded_message, _type} = Payload.encode(message, "json_protobuf")

      RailwayIpc.MessagePublishingMock
      |> expect(:process, fn ^message, %{exchange: ^exchange, queue: nil}, _ ->
        {:ok,
         %MessagePublishing{
           persisted_message: build(:published_message, %{encoded_message: encoded_message})
         }}
      end)

      :ok = RailwayIpc.Publisher.publish("channel", exchange, message, "json_protobuf")
    end

    test "it returns the error tuple on failure" do
      user_uuid = Ecto.UUID.generate()
      correlation_id = Ecto.UUID.generate()
      exchange = "events:a_thing"

      message =
        Events.AThingWasDone.new(%{
          user_uuid: user_uuid,
          correlation_id: correlation_id,
          uuid: Ecto.UUID.generate()
        })

      RailwayIpc.MessagePublishingMock
      |> expect(:process, fn ^message, %{exchange: ^exchange, queue: nil}, _ ->
        {:error,
         %MessagePublishing{
           error: "Failure to process message"
         }}
      end)

      {:error, "Failure to process message"} =
        RailwayIpc.Publisher.publish("channel", exchange, message, "json_protobuf")
    end
  end
end
