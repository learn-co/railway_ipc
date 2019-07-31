defmodule RailwayIpc.Core.RequestsConsumerTest do
  use ExUnit.Case
  alias RailwayIpc.Core.RequestsConsumer
  alias RailwayIpc.Core.Payload

  test "acks and replies when reply tuple returned" do
    {:ok, request} =
      Requests.RequestAThing.new(correlation_id: "123123", reply_to: "8675309")
      |> Payload.encode()

    {:ok, response} = Responses.RequestedThing.new(correlation_id: "123123") |> Payload.encode()

    {:ok, state} = Agent.start_link(fn -> %{acked: false, replied: false} end)

    RequestsConsumer.process(
      request,
      __MODULE__,
      fn ->
        Agent.update(state, &Map.put(&1, :acked, true))
      end,
      fn "8675309", ^response ->
        Agent.update(state, &Map.put(&1, :replied, true))
      end
    )

    assert Agent.get(state, & &1.acked)
    assert Agent.get(state, & &1.replied)
  end

  def handle_in(%Requests.RequestAThing{}) do
    {:reply, Responses.RequestedThing.new()}
  end
end
