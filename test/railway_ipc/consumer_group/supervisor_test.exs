defmodule RailwayIpc.ConsumerGroup.SupervisorTest do
  use ExUnit.Case
  import Mox
  alias RailwayIpc.ConsumerGroup.Supervisor, as: CGSupervisor
  setup :set_mox_global

  test "starts consumers in the group" do
    start_opts = [
      children: [
        RailwayIpc.Test.BatchEventsConsumer,
        RailwayIpc.Test.BatchCommandsConsumer
      ],
      name: :batch_consumers
    ]

    RailwayIpc.StreamMock
    |> expect(:setup_exchange_and_queue, 2, fn _, _, _ -> :ok end)
    |> expect(:consume, 2, fn _, _, _, _ -> {:ok, "My Tag"} end)

    {:ok, _supervisor} = start_supervised({CGSupervisor, start_opts})
    Process.sleep(100)

    assert RailwayIpc.Test.BatchEventsConsumer |> Process.whereis() |> Process.alive?()
  end

  test "stops all members of the group if one dies" do
    start_opts = [
      children: [
        RailwayIpc.Test.BatchEventsConsumer,
        RailwayIpc.Test.BatchCommandsConsumer
      ],
      name: :batch_consumers
    ]

    RailwayIpc.StreamMock
    |> expect(:setup_exchange_and_queue, 2, fn _, _, _ -> :ok end)
    |> expect(:consume, 2, fn _, _, _, _ -> {:ok, "My Tag"} end)

    {:ok, _supervisor} = start_supervised({CGSupervisor, start_opts})

    RailwayIpc.Test.BatchEventsConsumer
    |> Process.whereis()
    |> GenServer.stop()

    Process.sleep(100)

    refute RailwayIpc.Test.BatchCommandsConsumer |> Process.whereis()
  end

  test "Brings back children successfully" do
    start_opts = [
      children: [
        RailwayIpc.Test.BatchEventsConsumer,
        RailwayIpc.Test.BatchCommandsConsumer
      ],
      name: :batch_consumers
    ]

    RailwayIpc.StreamMock
    |> expect(:setup_exchange_and_queue, 4, fn _, _, _ -> :ok end)
    |> expect(:consume, 4, fn _, _, _, _ -> {:ok, "My Tag"} end)

    {:ok, _supervisor} = start_supervised({CGSupervisor, start_opts})

    RailwayIpc.Test.BatchEventsConsumer
    |> Process.whereis()
    |> GenServer.stop()

    Process.sleep(100)

    CGSupervisor.restart_tree(:batch_consumers)
    Process.sleep(100)
    assert RailwayIpc.Test.BatchEventsConsumer |> Process.whereis() |> Process.alive?()
    assert RailwayIpc.Test.BatchCommandsConsumer |> Process.whereis() |> Process.alive?()
  end
end
