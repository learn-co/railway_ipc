defmodule RailwayIpc.Core.EventsConsumerTest do
  use ExUnit.Case
  alias RailwayIpc.Core.EventsConsumer
  alias RailwayIpc.Core.Payload

  test "acks message if it processes well" do
    {:ok, payload} =
      Events.AThingWasDone.new()
      |> Payload.encode()

    {:ok, state} = Agent.start_link(fn -> %{acked: false} end)

    EventsConsumer.process(
      payload,
      __MODULE__,
      fn ->
        Agent.update(state, &Map.put(&1, :acked, true))
      end
    )

    assert Agent.get(state, & &1.acked)
  end

  test "acks when message parses to unknown module" do
    payload = "{\"encoded_message\":\"\",\"type\":\"Events::SomeUnknownThing\"}"
    {:ok, state} = Agent.start_link(fn -> %{acked: false} end)

    EventsConsumer.process(
      payload,
      __MODULE__,
      fn ->
        Agent.update(state, &Map.put(&1, :acked, true))
      end
    )

    assert Agent.get(state, & &1.acked)
  end

  test "acks and replies when reply tuple returned" do
    {:ok, payload} = Events.AThingWasDone.new() |> Payload.encode()
    {:ok, state} = Agent.start_link(fn -> %{acked: false} end)

    EventsConsumer.process(
      payload,
      __MODULE__,
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
