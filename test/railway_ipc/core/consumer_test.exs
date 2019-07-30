defmodule RailwayIpc.Core.ConsumerTest do
  use ExUnit.Case
  import Mox
  alias RailwayIpc.Core.Consumer

  test "acks message if it processes well" do
    payload = "Working"
    RailwayIpc.PayloadMock
    |> expect(
         :decode,
         fn ^payload ->
           {:ok, "good message"}
         end
       )
    {:ok, state} = Agent.start_link(fn -> %{acked: false, replied: false} end)

    Consumer.process(
      payload,
      __MODULE__,
      fn ->
        Agent.update(state, &(Map.put(&1, :acked, true)))
      end,
      fn (_reply_to, _reply) ->
        Agent.update(state, &(Map.put(&1, :replied, true)))
      end
    )

    assert Agent.get(state, &(&1.acked))
    refute Agent.get(state, &(&1.replied))
  end

  test "acks when message fails to parse" do
    payload = "bad data"
    RailwayIpc.PayloadMock
    |> expect(
         :decode,
         fn ^payload ->
           {:error, "Bad"}
         end
       )
    {:ok, state} = Agent.start_link(fn -> %{acked: false, replied: false} end)

    Consumer.process(
      payload,
      __MODULE__,
      fn ->
        Agent.update(state, &(Map.put(&1, :acked, true)))
      end,
      fn (_reply_to, _reply) ->
        Agent.update(state, &(Map.put(&1, :replied, true)))
      end
    )

    assert Agent.get(state, &(&1.acked))
    refute Agent.get(state, &(&1.replied))
  end

  test "acks when message parses, but processing fails" do
    payload = "bad processing"
    RailwayIpc.PayloadMock
    |> expect(
         :decode,
         fn ^payload ->
           {:ok, "will fail"}
         end
       )
    {:ok, state} = Agent.start_link(fn -> %{acked: false, replied: false} end)

    Consumer.process(
      payload,
      __MODULE__,
      fn ->
        Agent.update(state, &(Map.put(&1, :acked, true)))
      end,
      fn (_reply_to, _reply) ->
        Agent.update(state, &(Map.put(&1, :replied, true)))
      end
    )

    assert Agent.get(state, &(&1.acked))
    refute Agent.get(state, &(&1.replied))
  end

  test "acks and replies when reply tuple returned" do
    payload = "rpc"
    RailwayIpc.PayloadMock
    |> expect(
         :decode,
         fn ^payload ->
           {:ok, %{reply_to: "Reply Queue"}}
         end
       )
    |> expect(
         :encode,
         fn "Return value" ->
           {:ok, "Encoded"}
         end
       )
    {:ok, state} = Agent.start_link(fn -> %{acked: false, replied: false} end)

    Consumer.process(
      payload,
      __MODULE__,
      fn ->
        Agent.update(state, &(Map.put(&1, :acked, true)))
      end,
      fn ("Reply Queue", "Encoded") ->
        Agent.update(state, &(Map.put(&1, :replied, true)))
      end
    )

    assert Agent.get(state, &(&1.acked))
    assert Agent.get(state, &(&1.replied))
  end

  def handle_in("good message") do
    :ok
  end

  def handle_in("will fail") do
    {:error, "Oh no"}
  end

  def handle_in(%{reply_to: "Reply Queue"}) do
    {:reply, "Return value"}
  end
end
