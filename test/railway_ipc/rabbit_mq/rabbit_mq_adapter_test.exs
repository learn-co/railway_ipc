defmodule RailwayIpc.RabbitMQAdapterTest do
  use ExUnit.Case
  import Mox
  setup :verify_on_exit!
  alias RailwayIpc.RabbitMQ.RabbitMQAdapter, as: Rabbit

  test "connects to a queue" do
    {:ok, %AMQP.Connection{}} = Rabbit.connect()
  end

  test "returns channel" do
    {:ok, connection} = Rabbit.connect()
    {:ok, %AMQP.Channel{pid: _channel}} = Rabbit.get_channel(connection)
  end
end
