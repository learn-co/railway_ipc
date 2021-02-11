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
      fn _channel, _exchange, message ->
        {:ok, _decoded, _type} = Payload.decode(message)
      end
    )

    :ok
  end

  describe "prepare_message/1" do
    test "adds uuid to published message" do
      event = Events.AThingWasDone.new(user_uuid: "abcabc")

      with message <- RailwayIpc.Publisher.prepare_message(event),
           {:ok, decoded, _type} <- Payload.decode(message) do
        assert {:ok, _} = UUID.info(decoded.uuid)
      end
    end

    test "does not overwrite UUID if one already exists" do
      uuid = UUID.uuid1()
      event = Events.AThingWasDone.new(user_uuid: "abcabc", uuid: uuid)

      message = RailwayIpc.Publisher.prepare_message(event)
      assert {:ok, %{uuid: ^uuid}, _type} = Payload.decode(message)
    end
  end

  describe "publish/3" do
    test "it adds a uuid to the message" do
      message =
        Events.AThingWasDone.new(%{
          user_uuid: "user_uuid"
        })

      {:ok, encoded_message, _type} = Payload.encode(message)

      RailwayIpc.MessagePublishingMock
      |> expect(:process, fn %{uuid: uuid}, _ ->
        assert uuid != ""

        {:ok,
         %MessagePublishing{
           persisted_message: build(:published_message, %{encoded_message: encoded_message})
         }}
      end)

      RailwayIpc.Publisher.publish("channel", "events:a_thing", message)
    end

    test "it does not overwrite existing UUID" do
      message_uuid = Ecto.UUID.generate()

      message =
        Events.AThingWasDone.new(%{
          user_uuid: "user_uuid",
          uuid: message_uuid
        })

      {:ok, encoded_message, _type} = Payload.encode(message)

      RailwayIpc.MessagePublishingMock
      |> expect(:process, fn %{uuid: uuid}, _ ->
        assert uuid == message_uuid

        {:ok,
         %MessagePublishing{
           persisted_message: build(:published_message, %{encoded_message: encoded_message})
         }}
      end)

      RailwayIpc.Publisher.publish("channel", "events:a_thing", message)
    end

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

      {:ok, encoded_message, _type} = Payload.encode(message)

      RailwayIpc.MessagePublishingMock
      |> expect(:process, fn ^message, %{exchange: ^exchange, queue: nil} ->
        {:ok,
         %MessagePublishing{
           persisted_message: build(:published_message, %{encoded_message: encoded_message})
         }}
      end)

      RailwayIpc.Publisher.publish("channel", exchange, message)
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

      {:ok, encoded_message, _type} = Payload.encode(message)

      RailwayIpc.MessagePublishingMock
      |> expect(:process, fn ^message, %{exchange: ^exchange, queue: nil} ->
        {:ok,
         %MessagePublishing{
           persisted_message: build(:published_message, %{encoded_message: encoded_message})
         }}
      end)

      :ok = RailwayIpc.Publisher.publish("channel", exchange, message)
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
      |> expect(:process, fn ^message, %{exchange: ^exchange, queue: nil} ->
        {:error,
         %MessagePublishing{
           error: "Failure to process message"
         }}
      end)

      {:error, "Failure to process message"} =
        RailwayIpc.Publisher.publish("channel", exchange, message)
    end
  end
end
