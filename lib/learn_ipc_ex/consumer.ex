defmodule LearnIpcEx.Consumer do
  defmacro __using__(opts) do
    quote do
      use GenServer
      alias LearnIpcEx.Connection, as: IpcConn
      use AMQP

      def start_link(state) do
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
        payload
        |> Jason.decode!()
        |> __MODULE__.handle_in(meta)

        AMQP.Basic.ack(channel, meta.delivery_tag)
        {:noreply, state}
      end

      def handle_continue(:start_consuming, %{exchange: exchange, queue: queue} = state) do
        {:ok, channel} = IpcConn.consume(%{exchange: exchange, queue: queue})
        {:noreply, %{channel: channel}}
      end
    end
  end
end
