defmodule RailwayIpc.EventsConsumer do
  @moduledoc false
  defmacro __using__(opts) do
    quote do
      require Logger
      use GenServer

      @stream_adapter Application.get_env(
                        :railway_ipc,
                        :stream_adapter,
                        RailwayIpc.RabbitMQ.RabbitMQAdapter
                      )

      alias RailwayIpc.Connection, as: Connection
      alias RailwayIpc.Core.EventsConsumer
      alias RailwayIpc.Telemetry

      def start_link(_state) do
        exchange = Keyword.get(unquote(opts), :exchange)
        queue = Keyword.get(unquote(opts), :queue)
        GenServer.start_link(__MODULE__, %{exchange: exchange, queue: queue}, name: __MODULE__)
      end

      def init(state) do
        {:ok, state, {:continue, :start_consuming}}
      end

      def handle_info({:basic_consume_ok, _payload}, %{exchange: exchange, queue: queue} = state) do
        Telemetry.track_consumer_connected(%{exchange: exchange, queue: queue, module: __MODULE__})

        {:noreply, state}
      end

      def handle_info({:basic_deliver, payload, metadata}, state) do
        %{delivery_tag: delivery_tag} = metadata
        %{channel: channel, exchange: exchange, queue: queue} = state
        format = get_header(metadata, "message_format")
        Logger.metadata(feature: "railway_ipc_consumer")

        Telemetry.track_receive_message(
          %{payload: payload, delivery_tag: delivery_tag, exchange: exchange, queue: queue},
          fn ->
            # FIXME: Why do we pass this ack function around? We always ack,
            # and even if we want to reject at some point, we don't need to
            # pass a function around.
            #
            # Answer: It's just for tests; will refactor in the future.
            ack_function = fn ->
              @stream_adapter.ack(channel, delivery_tag)
            end

            result =
              EventsConsumer.process(payload, __MODULE__, exchange, queue, ack_function, format)

            {{:noreply, state}, %{result: result}}
          end
        )
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

      defp get_header(%{headers: :undefined}, name), do: nil

      defp get_header(%{headers: headers}, name) do
        {_, _, value} = Enum.find(headers, fn x -> {name, _, _} = x end)
        value
      end

      defp get_header(_, _), do: nil
    end
  end
end
