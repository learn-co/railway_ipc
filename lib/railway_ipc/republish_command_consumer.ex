defmodule RailwayIpc.RepublishCommandConsumer do
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
      alias RailwayIpc.Core.CommandsConsumer

      def start_link(_state) do
        queue = Keyword.get(unquote(opts), :queue)

        GenServer.start_link(
          __MODULE__,
          %{queue: queue},
          name: __MODULE__
        )
      end

      def init(state) do
        {:ok, state, {:continue, :start_consuming}}
      end

      def handle_info({:basic_consume_ok, _payload}, state), do: {:noreply, state}

      def handle_info(
            {:basic_deliver, payload, %{delivery_tag: delivery_tag}},
            %{
              channel: channel,
              queue: queue
            } = state
          ) do
        ack_function = fn ->
          @stream_adapter.ack(channel, delivery_tag)
        end

        publish_function = fn event ->
          RailwayIpc.Publisher.publish(event)
        end

        CommandsConsumer.process(
          payload,
          __MODULE__,
          nil,
          queue,
          ack_function,
          publish_function
        )

        {:noreply, state}
      end

      def handle_continue(:start_consuming, %{queue: queue} = state) do
        {:ok, channel} =
          Connection.consume(%{
            queue: queue,
            exchange: nil,
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
