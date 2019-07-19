defmodule LearnIpcEx.Connection do
  defstruct connection: nil,
            connection_ref: nil,
            channel: nil,
            consumer_specs: %{}

  use GenServer
  use AMQP

  def start_link(state) do
    GenServer.start_link(
      __MODULE__,
      :ok,
      name: __MODULE__
    )
  end

  def init(:ok) do
    send(self(), :open_amqp_connection)
    {:ok, %__MODULE__{}}
  end

  def channel do
    GenServer.call(__MODULE__, :channel)
  end

  def consume(opts) do
    opts = Map.put(opts, :consumer, self())
    GenServer.call(__MODULE__, {:consume, opts})
  end

  def handle_call(:channel, _from, state = %{channel: channel}) do
    {:reply, channel, state}
  end

  def handle_call(
        {:consume, spec},
        _from,
        state = %{channel: channel, consumer_specs: specs}
      ) do
    case bind_queue(channel, spec) do
      :ok ->
        %{consumer: consumer} = spec
        consumer_ref = Process.monitor(consumer)

        consumer_specs = Map.put(spec, consumer_ref, spec)
        {:reply, {:ok, channel}, %{state | consumer_specs: consumer_specs}}

      {:error, error} ->
        {:reply, {:error, error}, state}
    end
  end

  def handle_info(:open_amqp_connection, state = %{consumer_specs: consumer_specs}) do
    {:ok, state} = rabbitmq_connect(state)
    {:noreply, state}
  end

  def handle_info(
        {:DOWN, ref, :process, _pid, _reason},
        %{connection_ref: connection_ref} = state
      )
      when ref == connection_ref do
    {:ok, state} = rabbitmq_connect(state)
    {:noreply, state}
  end

  def handle_info(
        {:DOWN, ref, :process, _pid, _reason},
        %{consumer_specs: consumer_specs} = state
      ) do
    {_, consumer_specs} = pop_in(consumer_specs, [ref])
    {:noreply, %{state | consumer_specs: consumer_specs}}
  end

  def terminate(_reason, %{connection: connection}) do
    Connection.close(connection)
    {:stop, :normal}
  end

  defp rabbitmq_connect(%{consumer_specs: consumer_specs} = state) do
    {:ok, connection} = Connection.open("amqp://guest:guest@host.docker.internal:5672")
    connection_ref = Process.monitor(connection.pid)
    {:ok, channel} = Channel.open(connection)
    for {_ref, spec} <- consumer_specs, do: :ok = bind_queue(channel, spec)
    {:ok, %{state | connection: connection, connection_ref: connection_ref, channel: channel}}
  end

  defp bind_queue(channel, %{exchange: exchange, queue: queue, consumer: consumer}) do
    with {:ok, _} <- Queue.declare(channel, queue, durable: true),
         :ok <- Exchange.declare(channel, exchange, :fanout, durable: true),
         :ok <- Queue.bind(channel, queue, exchange),
         {:ok, _consumer_tag} <- Basic.consume(channel, queue, consumer) do
      :ok
    else
      error ->
        {:error, error}
    end
  end
end
