defmodule RailwayIpc.EventsConsumer do
  defmacro __using__(opts) do
    quote do
      use GenServer

      @stream_adapter Application.get_env(
                        :railway_ipc,
                        :stream_adapter,
                        RailwayIpc.RabbitMQ.RabbitMQAdapter
                      )

      alias RailwayIpc.Connection, as: Connection
      alias RailwayIpc.Core.EventsConsumer

      def start_link(_state) do
        exchange = Keyword.get(unquote(opts), :exchange)
        queue = Keyword.get(unquote(opts), :queue)
        GenServer.start_link(__MODULE__, %{exchange: exchange, queue: queue}, name: __MODULE__)
      end

      def init(state) do
        {:ok, state, {:continue, :start_consuming}}
      end

      def handle_info({:basic_consume_ok, _payload}, %{exchange: exchange, queue: queue} = state),
        do: {:noreply, state}

      def handle_info(
            {:basic_deliver, payload, %{delivery_tag: delivery_tag}},
            state = %{channel: channel, exchange: exchange, queue: queue}
          ) do
        ack_function = fn ->
          @stream_adapter.ack(channel, delivery_tag)
        end

        EventsConsumer.process(payload, __MODULE__, exchange, queue, ack_function)
        {:noreply, state}
      end

      def handle_continue(:start_consuming, %{exchange: exchange, queue: queue} = state) do
        {:ok, channel} =
          Connection.consume(%{
            exchange: exchange,
            queue: queue,
            consumer_pid: self(),
            consumer_module: __MODULE__
          })

        {:noreply, Map.put(state, :channel, channel)}
      end

      def handle_in(_payload) do
        :ok
      end

      defoverridable handle_in: 1
    end
  end
end
