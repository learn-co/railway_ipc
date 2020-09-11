defmodule RailwayIpc.Integration.RequestsConsumerTest do
  use RailwayIpc.DataCase

  defmodule RequestsConsumer do
    use RailwayIpc.RequestsConsumer,
      exchange: "integration_requests_events_exchange_test",
      queue: "ireet"

    def handle_in(%Requests.RequestAThing{}) do
      {:reply, Responses.RequestedThing.new()}
    end
  end

  defmodule RequestsClient do
    use RailwayIpc.Publisher, exchange: "integration_requests_events_exchange_test"
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

  test "returns a message over RPC" do
    {:ok, _pid} = start_supervised(RequestsConsumer)

    message =
      Requests.RequestAThing.new(
        user_uuid: Ecto.UUID.generate(),
        correlation_id: Ecto.UUID.generate(),
        context: %{"data" => "for the context"}
      )

    {:ok, response} = RequestsClient.publish_sync(message)
    assert response.user_uuid == message.user_uuid
    assert response.correlation_id == message.correlation_id
    assert response.context == message.context
  end
end
