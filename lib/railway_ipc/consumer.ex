defmodule RailwayIpc.Consumer do
  defmacro __using__(opts) do
    quote do
      require Logger
      use GenServer

      @stream_adapter Application.get_env(
                        :railway_ipc,
                        :stream_adapter,
                        RailwayIpc.RabbitMQ.RabbitMQAdapter
                      )
      @payload_converter Application.get_env(
                           :railway_ipc,
                           :payload_converter,
                           RailwayIpc.RabbitMQ.Payload
                         )

      alias RailwayIpc.Connection, as: Connection

      def start_link(_state) do
        exchange = Keyword.get(unquote(opts), :exchange)
        queue = Keyword.get(unquote(opts), :queue)
        GenServer.start_link(__MODULE__, %{exchange: exchange, queue: queue}, name: __MODULE__)
      end

      def init(state) do
        {:ok, state, {:continue, :start_consuming}}
      end

      def handle_info({:basic_consume_ok, _payload}, state) do
        {:noreply, state}
      end

      def handle_info({:basic_deliver, payload, meta}, state = %{channel: channel}) do
        with {:ok, message} <- @payload_converter.decode(payload),
             :ok <- __MODULE__.handle_in(message, meta) do
          @stream_adapter.ack(channel, meta.delivery_tag)
        else
          {:error, error} ->
            Logger.error("Failed to log message #{payload}, error #{error}")
            @stream_adapter.ack(channel, meta.delivery_tag)
        end

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

        {:noreply, %{channel: channel}}
      end

      def handle_in(_payload, _meta) do
        :ok
      end

      defoverridable handle_in: 2
    end
  end
end
