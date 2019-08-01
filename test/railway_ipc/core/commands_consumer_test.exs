defmodule RailwayIpc.Core.CommandsConsumerTest do
  use ExUnit.Case
  alias RailwayIpc.Core.CommandsConsumer
  alias RailwayIpc.Core.Payload

  test "acks message if it processes well" do
    {:ok, payload} =
      Commands.DoAThing.new(correlation_id: "123", context: %{"req_key" => "req_val"})
      |> Payload.encode()

    {:ok, event} =
      Events.AThingWasDone.new(
        correlation_id: "123",
        context: %{"req_key" => "req_val", "resp_key" => "resp_val"}
      )
      |> Payload.encode()

    {:ok, state} = Agent.start_link(fn -> %{acked: false, event_emitted: false} end)

    CommandsConsumer.process(
      payload,
      __MODULE__,
      fn ->
        Agent.update(state, &Map.put(&1, :acked, true))
      end,
      fn ^event ->
        Agent.update(state, &Map.put(&1, :event_emitted, true))
      end
    )

    assert Agent.get(state, & &1.acked)
    assert Agent.get(state, & &1.event_emitted)
  end

  test "acks when message when receiving an unknown command" do
    payload = "{\"encoded_message\":\"\",\"type\":\"Commands::SomeUnknownThing\"}"
    {:ok, state} = Agent.start_link(fn -> %{acked: false, event_emitted: false} end)

    CommandsConsumer.process(
      payload,
      __MODULE__,
      fn ->
        Agent.update(state, &Map.put(&1, :acked, true))
      end,
      fn _event ->
        Agent.update(state, &Map.put(&1, :event_emitted, true))
      end
    )

    assert Agent.get(state, & &1.acked)
    refute Agent.get(state, & &1.event_emitted)
  end

  def handle_in(%Commands.DoAThing{}) do
    {:emit, Events.AThingWasDone.new(context: %{"resp_key" => "resp_val"})}
  end
end
