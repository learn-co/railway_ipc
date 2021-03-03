defmodule E2E.PublisherTest do
  # Note that we need to use async: false since tests interact
  # with external Rabbit exchanges, queues, etc.
  use ExUnit.Case, async: false
  use RailwayIpc.DataCase
  use Test.Support.RabbitCase

  alias Events.AThingWasDone, as: Proto
  alias RailwayIpc.Connection
  alias Test.Support.Helpers

  @timeout _up_to_thirty_seconds = 30_000

  setup_all do
    {:ok, connection} = open_connection("amqp://guest:guest@localhost:5672")

    # Publishers don't know about queues, only exchanges. If we send a
    # message to an exchange that doesn't have a queue bound to it, the
    # message will be lost. In production, this isn't an issue since
    # consumers will take care of the binding. However, in the test env
    # we have to setup the queue ourselves since sometimes a consumer is
    # not set up, otherwise the test message will be lost.
    create_and_bind_queue(connection, "railway:test:events", "railway:test")

    pid = start_supervised!(%{id: Connection, start: {Connection, :start_link, []}})

    exit_fn = fn ->
      delete_queue(connection, "railway:test:events")
      delete_exchange(connection, "railway:test")
      close_connection(connection)
    end

    on_exit(exit_fn)
    %{connection: connection, pid: pid}
  end

  setup context do
    exit_fn = fn ->
      purge_queue(context.connection, "railway:test:events")
    end

    on_exit(exit_fn)
  end

  @tag :e2e
  test "successfully publish a message", context do
    # Make sure the queue is empty
    Helpers.wait_for_true(@timeout, fn ->
      assert 0 == queue_count("railway:test:events")
    end)

    # Get the current message count
    count_before = row_count("railway_ipc_published_messages")

    # Publish a message; this doesn't go through the macro - might want to
    # do that, haven't decided
    channel = Connection.publisher_channel(context.pid)
    proto = Proto.new()
    :ok = RailwayIpc.Publisher.publish(channel, "railway:test", proto, "json_protobuf")

    # Make sure it arrived in the queue
    Helpers.wait_for_true(@timeout, fn ->
      assert 1 == queue_count("railway:test:events")
    end)

    # Make sure the message was persisted
    count_after = row_count("railway_ipc_published_messages")
    assert 1 == count_after - count_before
  end
end
