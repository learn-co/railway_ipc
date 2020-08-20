defmodule RailwayIpc.Core.EventsConsumerTest do
  use ExUnit.Case
  alias RailwayIpc.Core.EventsConsumer
  alias RailwayIpc.Core.Payload
  import Mox

  test "acks message if it processes well" do
    {:ok, payload} =
      Events.AThingWasDone.new()
      |> Payload.encode()

    {:ok, state} = Agent.start_link(fn -> %{acked: false} end)

    exchange = "exchange"
    queue = "queue"

    handle_module = __MODULE__
    message_module = RailwayIpc.Core.EventMessage

    RailwayIpc.MessageConsumptionMock
    |> expect(:process, fn ^payload, ^handle_module, ^exchange, ^queue, ^message_module ->
      {:ok, %RailwayIpc.MessageConsumption{inbound_message: %{}}}
    end)

    EventsConsumer.process(
      payload,
      __MODULE__,
      exchange,
      queue,
      fn ->
        Agent.update(state, &Map.put(&1, :acked, true))
      end
    )

    assert Agent.get(state, & &1.acked)
  end

  test "acks when message parses to unknown module" do
    payload = "{\"encoded_message\":\"\",\"type\":\"Events::SomeUnknownThing\"}"
    {:ok, state} = Agent.start_link(fn -> %{acked: false} end)

    exchange = "exchange"
    queue = "queue"

    handle_module = __MODULE__
    message_module = RailwayIpc.Core.EventMessage

    RailwayIpc.MessageConsumptionMock
    |> expect(:process, fn ^payload, ^handle_module, ^exchange, ^queue, ^message_module ->
      {:error,
       %RailwayIpc.MessageConsumption{result: %{status: :error, reason: "Message type not found"}}}
    end)

    EventsConsumer.process(
      payload,
      __MODULE__,
      exchange,
      queue,
      fn ->
        Agent.update(state, &Map.put(&1, :acked, true))
      end
    )

    assert Agent.get(state, & &1.acked)
  end

  test "acks and replies when reply tuple returned" do
    {:ok, payload} = Events.AThingWasDone.new() |> Payload.encode()
    {:ok, state} = Agent.start_link(fn -> %{acked: false} end)

    exchange = "exchange"
    queue = "queue"

    handle_module = __MODULE__
    message_module = RailwayIpc.Core.EventMessage

    RailwayIpc.MessageConsumptionMock
    |> expect(:process, fn ^payload, ^handle_module, ^exchange, ^queue, ^message_module ->
      {:ok,
       %RailwayIpc.MessageConsumption{result: %{status: :error, reason: "Message type not found"}}}
    end)

    EventsConsumer.process(
      payload,
      __MODULE__,
      exchange,
      queue,
      fn ->
        Agent.update(state, &Map.put(&1, :acked, true))
      end
    )

    assert Agent.get(state, & &1.acked)
  end

  def handle_in(%Events.AThingWasDone{}) do
    :ok
  end
end
