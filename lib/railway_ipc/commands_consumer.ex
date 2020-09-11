defmodule RailwayIpc.CommandsConsumer do
  defmacro __using__(opts) do
    quote do
      use ExRabbitPool.Consumer
      alias RailwayIpc.Core.CommandsConsumer
      alias RailwayIpc.Telemetry
      require Logger

      @stream_adapter Application.get_env(
                        :railway_ipc,
                        :stream_adapter,
                        RailwayIpc.RabbitMQ.RabbitMQAdapter
                      )

      def start_consumer(config) do
        GenServer.start_link(__MODULE__, config, name: __MODULE__)
      end

      def setup_channel(%{adapter: adapter, queue: queue}, channel) do
        commands_exchange = Keyword.get(unquote(opts), :commands_exchange)
        adapter.setup_exchange_and_queue(channel, commands_exchange, queue)
      end

      def child_spec(_opts) do
        queue = Keyword.get(unquote(opts), :queue)

        %{
          id: __MODULE__,
          start:
            {__MODULE__, :start_consumer,
             [[pool_id: :consumer_pool, queue: queue, adapter: @stream_adapter]]},
          restart: :temporary,
          shutdown: 5000,
          type: :worker
        }
      end

      def basic_consume_ok(%{queue: queue}, consumer_tag) do
        commands_exchange = Keyword.get(unquote(opts), :commands_exchange)
        events_exchange = Keyword.get(unquote(opts), :events_exchange)

        Telemetry.track_consumer_connected(%{
          commands_exchange: commands_exchange,
          events_exchange: events_exchange,
          queue: queue,
          module: __MODULE__,
          consumer_tag: consumer_tag
        })

        :ok
      end

      def basic_deliver(%{adapter: adapter, channel: channel, queue: queue}, payload, %{
            delivery_tag: delivery_tag
          }) do
        Logger.metadata(feature: "railway_ipc_commands_consumer")
        commands_exchange = Keyword.get(unquote(opts), :commands_exchange)
        events_exchange = Keyword.get(unquote(opts), :events_exchange)

        ack_function = fn ->
          adapter.ack(channel, delivery_tag)
        end

        publish_function = fn event ->
          RailwayIpc.Publisher.publish(events_exchange, event)
        end

        CommandsConsumer.process(
          payload,
          __MODULE__,
          commands_exchange,
          queue,
          ack_function,
          publish_function
        )

        :ok
      end

      def handle_in(_payload), do: :ok
      defoverridable handle_in: 1
    end
  end
end
