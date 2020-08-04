defmodule RailwayIpc.CommandsConsumer do
  defmacro __using__(opts) do
    quote do
      use ExRabbitPool.Consumer
      alias RailwayIpc.Core.CommandsConsumer
      require Logger

      @stream_adapter Application.get_env(
                        :railway_ipc,
                        :stream_adapter,
                        RailwayIpc.RabbitMQ.RabbitMQAdapter
                      )

      def setup_channel(%{adapter: adapter, queue: queue}, channel) do
        events_exchange = Keyword.get(unquote(opts), :events_exchange)
        {:ok, _} = adapter.create_queue(channel, queue, durable: true)
        :ok = adapter.maybe_create_exchange(channel, events_exchange)
        :ok = adapter.maybe_bind_queue(channel, queue, events_exchange)
        :ok
      end

      def child_spec(_opts) do
        queue = Keyword.get(unquote(opts), :queue)

        %{
          id: __MODULE__,
          start:
            {__MODULE__, :start_link,
             [[pool_id: :consumer_pool, queue: queue, adapter: @stream_adapter]]},
          restart: :temporary,
          shutdown: 5000,
          type: :worker
        }
      end

      def basic_deliver(%{adapter: adapter, channel: channel, queue: queue}, payload, %{
            delivery_tag: delivery_tag
          }) do
        commands_exchange = Keyword.get(unquote(opts), :commands_exchange)
        events_exchange = Keyword.get(unquote(opts), :events_exchange)

        ack_function = fn ->
          adapter.ack(channel, delivery_tag)
        end

        publish_function = fn event ->
          RailwayIpc.Publisher.publish(channel, events_exchange, event)
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
