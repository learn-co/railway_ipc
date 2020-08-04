defmodule RailwayIpc.EventsConsumer do
  defmacro __using__(opts) do
    quote do
      use ExRabbitPool.Consumer
      alias RailwayIpc.Core.EventsConsumer
      require Logger

      @stream_adapter Application.get_env(
                        :railway_ipc,
                        :stream_adapter,
                        RailwayIpc.RabbitMQ.RabbitMQAdapter
                      )

      def setup_channel(%{adapter: adapter, queue: queue}, channel) do
        exchange = Keyword.get(unquote(opts), :exchange)
        {:ok, _} = adapter.declare_queue(channel, queue, durable: true)
        :ok = adapter.declare_exchange(channel, exchange, type: :fanout)
        :ok = adapter.queue_bind(channel, queue, exchange)
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
        exchange = Keyword.get(unquote(opts), :exchange)

        ack_function = fn ->
          @stream_adapter.ack(channel, delivery_tag)
        end

        EventsConsumer.process(payload, __MODULE__, exchange, queue, ack_function)
        :ok
      end

      def handle_in(_payload), do: :ok
      defoverridable handle_in: 1
    end
  end
end
