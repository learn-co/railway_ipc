defmodule RailwayIpc.PublisherTest do
  use ExUnit.Case
  import Mox
  import RailwayIpc.Factory
  setup :set_mox_global
  setup :verify_on_exit!

  alias RailwayIpc.{StreamMock, MessagePublishing}
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

    StreamMock
    |> stub(
      :publish,
      fn _channel, _exchange, message ->
        {:ok, _decoded} = Payload.decode(message)
      end
    )

    :ok
  end

  describe "prepare_message/1" do
    test "adds uuid to published message" do
      command = Events.AThingWasDone.new(user_uuid: "abcabc")

      with message <- RailwayIpc.Publisher.prepare_message(command),
           {:ok, decoded} <- Payload.decode(message) do
        assert {:ok, _} = UUID.info(decoded.uuid)
      end
    end

    test "does not overwrite UUID if one already exists" do
      uuid = UUID.uuid1()
      command = Events.AThingWasDone.new(user_uuid: "abcabc", uuid: uuid)

      message = RailwayIpc.Publisher.prepare_message(command)
      assert {:ok, %{uuid: ^uuid}} = Payload.decode(message)
    end
  end

  describe "publish/3" do
    test "it adds a uuid to the message" do
      message =
        Commands.DoAThing.new(%{
          user_uuid: "user_uuid"
        })

      {:ok, encoded_message} = Payload.encode(message)

      RailwayIpc.MessagePublishingMock
      |> expect(:process, fn %{uuid: uuid}, _ ->
        assert uuid != ""

        {:ok,
         %MessagePublishing{
           persisted_message: build(:published_message, %{encoded_message: encoded_message})
         }}
      end)

      RailwayIpc.Publisher.publish("commands:a_thing", message)
    end

    test "it does not overwrite existing UUID" do
      message_uuid = Ecto.UUID.generate()

      message =
        Commands.DoAThing.new(%{
          user_uuid: "user_uuid",
          uuid: message_uuid
        })

      {:ok, encoded_message} = Payload.encode(message)

      RailwayIpc.MessagePublishingMock
      |> expect(:process, fn %{uuid: uuid}, _ ->
        assert uuid == message_uuid

        {:ok,
         %MessagePublishing{
           persisted_message: build(:published_message, %{encoded_message: encoded_message})
         }}
      end)

      RailwayIpc.Publisher.publish("commands:a_thing", message)
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

      RailwayIpc.MessagePublishingMock
      |> expect(:process, fn ^message, %{exchange: ^exchange, queue: nil} ->
        {:ok,
         %MessagePublishing{
           persisted_message: build(:published_message, %{encoded_message: encoded_message})
         }}
      end)

      RailwayIpc.Publisher.publish(exchange, message)
    end

    test "it returns :ok on publish sucess" do
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

      RailwayIpc.MessagePublishingMock
      |> expect(:process, fn ^message, %{exchange: ^exchange, queue: nil} ->
        {:ok,
         %MessagePublishing{
           persisted_message: build(:published_message, %{encoded_message: encoded_message})
         }}
      end)

      :ok = RailwayIpc.Publisher.publish(exchange, message)
    end

    test "it returns the error tuple on failure" do
      user_uuid = Ecto.UUID.generate()
      correlation_id = Ecto.UUID.generate()
      exchange = "commands:a_thing"

      message =
        Commands.DoAThing.new(%{
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

      {:error, "Failure to process message"} = RailwayIpc.Publisher.publish(exchange, message)
    end
  end

  describe "direct_publish/3" do
    setup do
      StreamMock
      |> stub(
        :direct_publish,
        fn _channel, _queue, message ->
          {:ok, _decoded} = Payload.decode(message)
        end
      )

      :ok
    end

    test "it adds a uuid to the message" do
      message =
        RailwayIpc.Commands.RepublishMessage.new(%{
          user_uuid: Ecto.UUID.generate()
        })

      {:ok, encoded_message} = Payload.encode(message)

      RailwayIpc.MessagePublishingMock
      |> expect(:process, fn %{uuid: uuid}, _ ->
        assert uuid != ""

        {:ok,
         %MessagePublishing{
           persisted_message: build(:published_message, %{encoded_message: encoded_message})
         }}
      end)

      :ok = RailwayIpc.Publisher.direct_publish("queue", message)
    end

    test "it does not overwrite existing UUID" do
      message_uuid = Ecto.UUID.generate()

      message =
        RailwayIpc.Commands.RepublishMessage.new(%{
          user_uuid: Ecto.UUID.generate(),
          uuid: message_uuid
        })

      {:ok, encoded_message} = Payload.encode(message)

      RailwayIpc.MessagePublishingMock
      |> expect(:process, fn %{uuid: uuid}, _ ->
        assert uuid == message_uuid

        {:ok,
         %MessagePublishing{
           persisted_message: build(:published_message, %{encoded_message: encoded_message})
         }}
      end)

      :ok = RailwayIpc.Publisher.direct_publish("queue", message)
    end

    test "it returns :ok on success" do
      user_uuid = Ecto.UUID.generate()
      correlation_id = Ecto.UUID.generate()
      queue = "republish_queue"

      message =
        RailwayIpc.Commands.RepublishMessage.new(%{
          user_uuid: user_uuid,
          correlation_id: correlation_id,
          uuid: Ecto.UUID.generate()
        })

      {:ok, encoded_message} = Payload.encode(message)

      RailwayIpc.MessagePublishingMock
      |> expect(:process, fn ^message, %{queue: ^queue} ->
        {:ok,
         %MessagePublishing{
           persisted_message: build(:published_message, %{encoded_message: encoded_message})
         }}
      end)

      :ok = RailwayIpc.Publisher.direct_publish(queue, message)
    end

    test "it returns the error tuple on failure" do
      user_uuid = Ecto.UUID.generate()
      correlation_id = Ecto.UUID.generate()
      queue = "republish_queue"

      message =
        RailwayIpc.Commands.RepublishMessage.new(%{
          user_uuid: user_uuid,
          correlation_id: correlation_id,
          uuid: Ecto.UUID.generate()
        })

      RailwayIpc.MessagePublishingMock
      |> expect(:process, fn ^message, %{queue: ^queue} ->
        {:error,
         %MessagePublishing{
           error: "Failed to process message"
         }}
      end)

      {:error, "Failed to process message"} = RailwayIpc.Publisher.direct_publish(queue, message)
    end
  end
end
