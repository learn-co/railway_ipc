defmodule RailwayIpc.EventsConsumer do
  defmacro __using__(opts) do
    quote do
      require Logger
      use GenServer

      @default_arguments [
        {"x-dead-letter-exchange", :longstr, "ipc:errors"}
      ]

      @stream_adapter Application.get_env(
                        :railway_ipc,
                        :stream_adapter,
                        RailwayIpc.RabbitMQ.RabbitMQAdapter
                      )

      alias RailwayIpc.Telemetry
      alias RailwayIpc.Connection, as: Connection
      alias RailwayIpc.Core.EventsConsumer

      def start_link(_state) do
        exchange = Keyword.get(unquote(opts), :exchange)
        queue = Keyword.get(unquote(opts), :queue)

        arguments = Keyword.get(unquote(opts), :arguments) || @default_arguments

        GenServer.start_link(
          __MODULE__,
          %{exchange: exchange, queue: queue, arguments: arguments},
          name: __MODULE__
        )
      end

      def init(state) do
        {:ok, state, {:continue, :start_consuming}}
      end

      def handle_info({:basic_consume_ok, _payload}, %{exchange: exchange, queue: queue} = state) do
        Telemetry.track_consumer_connected(%{exchange: exchange, queue: queue, module: __MODULE__})

        {:noreply, state}
      end

      def handle_info(
            {:basic_deliver, payload, %{delivery_tag: delivery_tag}},
            state = %{channel: channel, exchange: exchange, queue: queue}
          ) do
        Logger.metadata(feature: "railway_ipc_consumer")

        Telemetry.track_receive_message(
          %{payload: payload, delivery_tag: delivery_tag, exchange: exchange, queue: queue},
          fn ->
            ack_function = fn ->
              @stream_adapter.ack(channel, delivery_tag)
            end

            result = EventsConsumer.process(payload, __MODULE__, exchange, queue, ack_function)
            {{:noreply, state}, %{result: result}}
          end
        )
      end

      def handle_continue(
            :start_consuming,
            %{exchange: exchange, queue: queue, arguments: arguments} = state
          ) do
        IO.puts("State in EventsConsumer.handle_continue/2")
        IO.inspect(state)

        {:ok, channel} =
          Connection.consume(%{
            exchange: exchange,
            queue: queue,
            arguments: arguments,
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
