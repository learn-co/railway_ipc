defmodule RailwayIpc.RepublishedMessagesConsumerTest do
  use ExUnit.Case
  import Mox
  import RailwayIpc.Factory
  setup :verify_on_exit!
  setup :set_mox_global

  alias RailwayIpc.Ipc.RepublishedMessagesConsumer
  alias RailwayIpc.{Connection, StreamMock}
  alias RailwayIpc.Core.Payload
  @queue "railway_ipc:republished_messages:commands"

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
            RepublishedMessagesConsumer => %{
              pid: self()
            }
          },
          %{pid: self()}
        }
      end
    )

    persisted_published_message = build(:published_message)
    uuid = persisted_published_message.uuid

    RailwayIpc.PersistenceMock
    |> stub(:get_published_message, fn ^uuid ->
      persisted_published_message
    end)

    Connection.start_link(name: Connection)

    [persisted_published_message: persisted_published_message]
  end

  test "starts and names process" do
    {:ok, pid} = RepublishedMessagesConsumer.start_link(:ok)
    found_pid = Process.whereis(RepublishedMessagesConsumer)
    assert found_pid == pid
  end

  test "acks message when successful", %{persisted_published_message: persisted_published_message} do
    data =
      RailwayIpc.Commands.RepublishMessage.Data.new(
        published_message_uuid: persisted_published_message.uuid
      )

    {:ok, command} =
      RailwayIpc.Commands.RepublishMessage.new(correlation_id: "123", data: data)
      |> Payload.encode()

    consumer_module = RepublishedMessagesConsumer
    message_module = RailwayIpc.Core.CommandMessage
    queue = @queue
    events_exchange = persisted_published_message.exchange

    StreamMock
    |> expect(
      :bind_queue,
      fn %{pid: _conn_pid},
         %{
           consumer_module: ^consumer_module,
           consumer_pid: _pid,
           queue: ^queue
         } ->
        :ok
      end
    )
    |> expect(
      :publish,
      fn _channel, ^events_exchange, _encoded ->
        :ok
      end
    )
    |> expect(:ack, fn %{pid: _pid}, "tag" -> :ok end)

    {:ok, pid} = RepublishedMessagesConsumer.start_link(:ok)

    RailwayIpc.MessageConsumptionMock
    |> expect(:process, fn ^command, ^consumer_module, nil, ^queue, ^message_module ->
      {:emit, %{outbound_message: persisted_published_message}}
    end)

    send(pid, {:basic_deliver, command, %{delivery_tag: "tag"}})
    # yey async programming
    Process.sleep(100)
  end

  test "acks message even if there's an issue with the payload" do
    consumer_module = RepublishedMessagesConsumer
    queue = @queue
    message_module = RailwayIpc.Core.CommandMessage

    StreamMock
    |> expect(
      :bind_queue,
      fn %{pid: _conn_pid},
         %{
           consumer_module: ^consumer_module,
           consumer_pid: _pid,
           queue: ^queue
         } ->
        :ok
      end
    )
    |> expect(:ack, fn %{pid: _pid}, "tag" -> :ok end)

    {:ok, pid} = RepublishedMessagesConsumer.start_link(:ok)
    message = "{\"encoded_message\":\"\",\"type\":\"Events::SomeUnknownThing\"}"

    RailwayIpc.MessageConsumptionMock
    |> expect(:process, fn ^message, ^consumer_module, nil, ^queue, ^message_module ->
      {:error, %RailwayIpc.MessageConsumption{result: %{reason: "error message"}}}
    end)

    send(pid, {:basic_deliver, message, %{delivery_tag: "tag"}})
    # yey async programming
    Process.sleep(100)
  end
end
