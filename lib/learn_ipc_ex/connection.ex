defmodule LearnIpcEx.Connection do
  @amqp_adapter Application.get_env(:learn_ipc_ex, :amqp_adapter)

  defstruct connection: nil,
            connection_ref: nil,
            channel: nil,
            consumer_specs: %{}

  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    {:ok, %__MODULE__{}, {:continue, :open_amqp_connection}}
  end

  def channel do
    GenServer.call(__MODULE__, :channel)
  end

  def consume(opts) do
    opts = Map.put(opts, :consumer, self())
    GenServer.call(__MODULE__, {:consume, opts})
  end

  def handle_continue(:open_amqp_connection, state) do
    {:ok, state} = rabbitmq_connect(state)
    {:noreply, state}
  end

  def handle_call(:channel, _from, state = %{channel: channel}) do
    {:reply, channel, state}
  end

  def handle_call(
        {:consume, spec},
        _from,
        state = %{channel: channel, consumer_specs: specs}
      ) do
    case @amqp_adapter.bind_queue(channel, spec) do
      :ok ->
        %{consumer: consumer} = spec
        consumer_ref = Process.monitor(consumer)

        consumer_specs = Map.put(specs, consumer_ref, spec)
        {:reply, {:ok, channel}, %{state | consumer_specs: consumer_specs}}

      {:error, error} ->
        {:reply, {:error, error}, state}
    end
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

  def terminate(reason, %{connection: nil}) do
    IO.inspect reason
    {:stop, :normal}
  end
  def terminate(reason, %{connection: connection}) do
    IO.inspect reason
    @amqp_adapter.close_connection(connection)
    {:stop, :normal}
  end

  defp rabbitmq_connect(%{consumer_specs: consumer_specs} = state) do
    {:ok, %{connection: connection, channel: channel}} = @amqp_adapter.connect()
    connection_ref = Process.monitor(connection.pid)
    for {_ref, spec} <- consumer_specs, do: :ok = @amqp_adapter.bind_queue(channel, spec)
    {:ok, %{state | connection: connection, connection_ref: connection_ref, channel: channel}}
  end
end
