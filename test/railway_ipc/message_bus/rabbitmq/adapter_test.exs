defmodule RailwayIpc.MessageBus.RabbitMQ.AdapterTest do
  use ExUnit.Case

  alias RailwayIpc.MessageBus.RabbitMQ.Adapter
  alias RailwayIpc.MessageBus.RabbitMQ.Logger, as: RabbitLog

  setup :attach_telemetry_handlers

  test "connect to RabbitMQ" do
    assert {:ok, %AMQP.Connection{pid: pid}} = Adapter.connect()
    assert Process.alive?(pid)

    assert_receive {
      :telemetry_event,
      [:railway_ipc, :rabbitmq, :connection, :open],
      %{system_time: _},
      %{module: _}
    }
  end

  test "disconnect from RabbitMQ" do
    {:ok, pid} = Adapter.connect()

    assert :ok = Adapter.disconnect(pid)

    assert_receive {
      :telemetry_event,
      [:railway_ipc, :rabbitmq, :connection, :closed],
      %{system_time: _},
      %{module: _}
    }
  end

  test "disconnect when connection is nil" do
    assert :ok = Adapter.disconnect(nil)
  end

  test "disconnect when connection is already closed" do
    {:ok, pid} = Adapter.connect()

    assert :ok = Adapter.disconnect(pid)
    assert :ok = Adapter.disconnect(pid)
  end

  defp attach_telemetry_handlers(%{test: test}) do
    self = self()

    :ok =
      :telemetry.attach_many(
        "#{test}",
        RabbitLog.events(),
        fn name, measurements, metadata, _config ->
          send(self, {:telemetry_event, name, measurements, metadata})
        end,
        nil
      )
  end
end
