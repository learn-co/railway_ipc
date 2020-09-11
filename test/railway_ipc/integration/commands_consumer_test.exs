defmodule RailwayIpc.Integration.CommandsConsumerTest do
  use RailwayIpc.DataCase

  defmodule CommandsConsumer do
    use RailwayIpc.CommandsConsumer,
      commands_exchange: "integration_commands_commands_exchange_test",
      events_exchange: "integration_commands_events_exchange_test",
      queue: "iccet"

    def handle_in(%Commands.DoAThing{}) do
      {:emit, Events.AThingWasDone.new()}
    end
  end

  defmodule EventsConsumer do
    use RailwayIpc.EventsConsumer,
      exchange: "integration_commands_events_exchange_test",
      queue: "iceet"

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

  test "properly emits a response" do
    {:ok, _pid} = start_supervised(CommandsConsumer)
    {:ok, pid} = start_supervised(EventsConsumer)
    send(pid, {:register_test, self()})

    message =
      Commands.DoAThing.new(
        user_uuid: Ecto.UUID.generate(),
        correlation_id: Ecto.UUID.generate(),
        context: %{"data" => "for the context"}
      )

    RailwayIpc.Publisher.publish("integration_commands_commands_exchange_test", message)
    assert_receive {:message_received, %Events.AThingWasDone{} = received_message}
    assert received_message.user_uuid == message.user_uuid
    assert received_message.correlation_id == message.correlation_id
    assert received_message.context == message.context
  end
end
