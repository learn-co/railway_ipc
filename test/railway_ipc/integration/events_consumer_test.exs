defmodule RailwayIpc.Integration.EventsConsumerTest do
  use RailwayIpc.DataCase

  defmodule EventsConsumer do
    use RailwayIpc.EventsConsumer, exchange: "integration_events_test", queue: "iet"

    def handle_info({:register_test, test_pid}, state) do
      config = state.config ++ [test_pid: test_pid]
      {:noreply, Map.put(state, :config, config)}
    end

    def handle_info({:report, msg}, state) do
      send(state.config[:test_pid], {:message_received, msg})
      {:noreply, state}
    end

    def handle_in(msg) do
      send(self(), {:report, msg})
      :ok
    end
  end

  import Mox
  setup :set_mox_global
  alias RailwayIpc.StreamMock

  setup do
    StreamMock
    |> stub_with(RailwayIpc.RabbitMQ.RabbitMQAdapter)

    RailwayIpc.MessagePublishingMock
    |> stub_with(RailwayIpc.MessagePublishing)

    RailwayIpc.PersistenceMock
    |> stub_with(RailwayIpc.Persistence)

    RailwayIpc.MessageConsumptionMock
    |> stub_with(RailwayIpc.MessageConsumption)

    :ok
  end

  test "properly handles an event" do
    {:ok, pid} = start_supervised(EventsConsumer)
    send(pid, {:register_test, self()})

    message =
      Events.AThingWasDone.new(
        user_uuid: Ecto.UUID.generate(),
        correlation_id: Ecto.UUID.generate(),
        context: %{"data" => "for the context"},
        data: Events.AThingWasDone.Data.new(value: "A good one")
      )

    RailwayIpc.Publisher.publish("integration_events_test", message)
    assert_receive {:message_received, received_message}
    assert received_message.user_uuid == message.user_uuid
    assert received_message.correlation_id == message.correlation_id
    assert received_message.context == message.context
    assert received_message.data == message.data
  end
end
