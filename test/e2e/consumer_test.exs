defmodule E2E.ConsumerTest do
  # Note that we need to use async: false since tests interact
  # with external Rabbit exchanges, queues, etc.
  use ExUnit.Case, async: false
  use RailwayIpc.DataCase
  use Test.Support.RabbitCase

  alias Events.AThingWasDone, as: Proto
  alias RailwayIpc.Core.MessageFormat.BinaryProtobuf
  alias RailwayIpc.Core.MessageFormat.JsonProtobuf
  alias Test.Support.Helpers

  @timeout _up_to_thirty_seconds = 30_000

  defmodule Subject do
    use RailwayIpc.EventsConsumer,
      exchange: "railway:test",
      queue: "railway:test:events"

    def handle_in(_payload) do
      :ok
    end
  end

  setup do
    {:ok, connection} = open_connection("amqp://guest:guest@localhost:5672")
    {:ok, channel} = open_channel(connection)

    # Publishers don't know about queues, only exchanges. If we send a
    # message to an exchange that doesn't have a queue bound to it, the
    # message will be lost. In production, this isn't an issue since
    # consumers will take care of the binding. However, in the test env
    # we have to setup the queue ourselves since sometimes a consumer is
    # not set up, otherwise the test message will be lost.
    create_and_bind_queue(connection, "railway:test:events", "railway:test")

    exit_fn = fn ->
      delete_queue(connection, "railway:test:events")
      delete_exchange(connection, "railway:test")
      close_channel(channel)
      close_connection(connection)
    end

    on_exit(exit_fn)
    %{connection: connection, channel: channel}
  end

  @tag :e2e
  test "successfully consumes a message in binary protobuf format", context do
    # Make sure the queue is empty
    Helpers.wait_for_true(@timeout, fn ->
      assert 0 == queue_count("railway:test:events")
    end)

    # Publish a message
    proto = Proto.new(uuid: UUID.uuid4())
    {:ok, encoded, _type} = BinaryProtobuf.encode(proto)
    :ok = publish_message(context.channel, "railway:test", encoded)

    # Make sure it arrived in the queue
    Helpers.wait_for_true(@timeout, fn ->
      assert 1 == queue_count("railway:test:events")
    end)

    # Get the current message count
    count_before = row_count("railway_ipc_consumed_messages")

    # Start the consumer
    start_supervised!(%{id: Subject, start: {Subject, :start_link, [:ok]}})

    # Assert the consumer processed the message
    Helpers.wait_for_true(@timeout, fn ->
      assert 0 == queue_count("railway:test:events")
    end)

    # Make sure the message was persisted
    count_after = row_count("railway_ipc_consumed_messages")
    assert 1 == count_after - count_before
  end

  @tag :e2e
  test "successfully consumes a message in json protobuf format", context do
    # Make sure the queue is empty
    Helpers.wait_for_true(@timeout, fn ->
      assert 0 == queue_count("railway:test:events")
    end)

    # Publish a message
    proto = Proto.new(uuid: UUID.uuid4())
    {:ok, encoded, _type} = JsonProtobuf.encode(proto)

    :ok =
      publish_message(
        context.channel,
        "railway:test",
        encoded,
        headers: [message_format: "json_protobuf"]
      )

    # Make sure it arrived in the queue
    Helpers.wait_for_true(@timeout, fn ->
      assert 1 == queue_count("railway:test:events")
    end)

    # Get the current message count
    count_before = row_count("railway_ipc_consumed_messages")

    # Start the consumer
    start_supervised!(%{id: Subject, start: {Subject, :start_link, [:ok]}})

    # Assert the consumer processed the message
    Helpers.wait_for_true(@timeout, fn ->
      assert 0 == queue_count("railway:test:events")
    end)

    # Make sure the message was persisted
    count_after = row_count("railway_ipc_consumed_messages")
    assert 1 == count_after - count_before
  end
end
