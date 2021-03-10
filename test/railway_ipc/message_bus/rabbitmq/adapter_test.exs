defmodule RailwayIpc.MessageBus.RabbitMQ.AdapterTest do
  use ExUnit.Case
  use Test.Support.RabbitCase

  alias RailwayIpc.MessageBus.Publisher
  alias RailwayIpc.MessageBus.RabbitMQ.Adapter
  alias RailwayIpc.MessageBus.RabbitMQ.Logger, as: RabbitLog

  setup :attach_telemetry_handlers

  test "setup publisher" do
    {:ok, %Publisher{connection: connection, channel: channel}} = Adapter.setup_publisher()

    assert Process.alive?(connection.pid)
    assert Process.alive?(channel.pid)

    assert_receive {
      :telemetry_event,
      [:railway_ipc, :rabbitmq, :connection, :open],
      %{system_time: _},
      %{module: _}
    }
  end

  test "cleanup publisher" do
    {:ok, %Publisher{connection: connection, channel: channel} = state} =
      Adapter.setup_publisher()

    :ok = Adapter.cleanup_publisher(state)
    refute Process.alive?(connection.pid)
    refute Process.alive?(channel.pid)

    assert_receive {
      :telemetry_event,
      [:railway_ipc, :rabbitmq, :connection, :closed],
      %{system_time: _},
      %{module: _}
    }
  end

  test "cleanup publisher when connection and channel are already closed" do
    {:ok, %Publisher{connection: connection, channel: channel} = state} =
      Adapter.setup_publisher()

    :ok = close_channel(channel)
    :ok = close_connection(connection)
    assert :ok == Adapter.cleanup_publisher(state)
  end

  test "cleanup publisher when connection and channel are nil" do
    assert :ok == Adapter.cleanup_publisher(%Publisher{})
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
