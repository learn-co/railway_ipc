defmodule RailwayIpc.Core.RequestsConsumerTest do
  use ExUnit.Case
  alias RailwayIpc.Core.Payload
  alias RailwayIpc.Core.RequestsConsumer

  test "acks and replies when reply tuple returned" do
    {:ok, request} =
      Requests.RequestAThing.new(
        correlation_id: "123123",
        context: %{"request_context" => "req_value"},
        reply_to: "8675309"
      )
      |> Payload.encode()

    response =
      Responses.RequestedThing.new(
        correlation_id: "123123",
        context: %{"request_context" => "req_value", "resp_key" => "resp_value"}
      )

    {:ok, state} = Agent.start_link(fn -> %{acked: false, replied: false} end)

    RequestsConsumer.process(
      request,
      __MODULE__,
      fn ->
        Agent.update(state, &Map.put(&1, :acked, true))
      end,
      fn ^response, "8675309" ->
        Agent.update(state, &Map.put(&1, :replied, true))
      end
    )

    assert Agent.get(state, & &1.acked)
    assert Agent.get(state, & &1.replied)
  end

  def handle_in(%Requests.RequestAThing{}) do
    {:reply, Responses.RequestedThing.new(context: %{"resp_key" => "resp_value"})}
  end
end
