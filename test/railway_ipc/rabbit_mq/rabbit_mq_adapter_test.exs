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

  test "creates queue if it doesn't exist" do
    exchange_name = "BogusExchangeName"
    {:ok, connection} = Rabbit.connect()
    {:ok, channel} = Rabbit.get_channel(connection)
    :ok = AMQP.Exchange.delete(channel, exchange_name)
    :ok = Rabbit.publish(channel, exchange_name, %{})
    assert has_exchange?(exchange_name)
  end

  def has_exchange?(exchange_name) do
    api_url = (System.get_env("RABBITMQ_API_URL") <> "exchanges") |> String.to_charlist()
    {:ok, {_, _, resp}} = :httpc.request(api_url)

    Jason.decode!(resp, keys: :atoms)
    |> Enum.any?(&(&1.name == exchange_name))
  end
end
