defmodule RailwayIpc.RequestsConsumer do
  defmacro __using__(opts) do
    quote do
      use ExRabbitPool.Consumer
      alias RailwayIpc.Core.RequestsConsumer
      require Logger

      @stream_adapter Application.get_env(
                        :railway_ipc,
                        :stream_adapter,
                        RailwayIpc.RabbitMQ.RabbitMQAdapter
                      )
      alias RailwayIpc.Telemetry
      alias RailwayIpc.Connection, as: Connection
      alias RailwayIpc.Core.RequestsConsumer

      def start_consumer(config) do
        GenServer.start_link(__MODULE__, config, name: __MODULE__)
      end

      def setup_channel(%{adapter: adapter, queue: queue}, channel) do
        exchange = Keyword.get(unquote(opts), :exchange)
        adapter.setup_exchange_and_queue(channel, exchange, queue)
      end

      def child_spec(_opts) do
        queue = Keyword.get(unquote(opts), :queue)

        %{
          id: __MODULE__,
          start:
            {__MODULE__, :start_consumer,
             [[pool_id: :consumer_pool, queue: queue, adapter: @stream_adapter]]},
          restart: :permanent,
          shutdown: 5000,
          type: :worker
        }
      end

      def basic_consume_ok(%{queue: queue}, consumer_tag) do
        exchange = Keyword.get(unquote(opts), :exchange)

        Telemetry.track_consumer_connected(%{
          exchange: exchange,
          queue: queue,
          module: __MODULE__,
          consumer_tag: consumer_tag
        })

        :ok
      end

      def basic_deliver(%{adapter: adapter, channel: channel, queue: queue}, payload, %{
            delivery_tag: delivery_tag
          }) do
        exchange = Keyword.get(unquote(opts), :exchange)
        Logger.metadata(feature: "railway_ipc_request")

        Telemetry.track_receive_message(
          %{payload: payload, delivery_tag: delivery_tag, exchange: exchange, queue: queue},
          fn ->
            ack_function = fn -> adapter.ack(channel, delivery_tag) end

            reply_function = fn reply, reply_to ->
              RailwayIpc.Publisher.reply(channel, reply_to, reply)
            end

            result = RequestsConsumer.process(payload, __MODULE__, ack_function, reply_function)
            {:ok, %{result: result}}
          end
        )
      end

      def handle_in(_payload), do: :ok
      defoverridable handle_in: 1
    end
  end
end
