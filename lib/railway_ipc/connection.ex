defmodule RailwayIpc.Connection do
  @stream_adapter Application.get_env(
                    :railway_ipc,
                    :stream_adapter,
                    RailwayIpc.RabbitMQ.RabbitMQAdapter
                  )

  defstruct connection: nil,
            publisher_channel: nil,
            consumer_channels: %{}

  use GenServer
  require Logger

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    {:ok, %__MODULE__{}, {:continue, :open_connection}}
  end

  def publisher_channel(connection \\ __MODULE__) do
    GenServer.call(connection, :publisher_channel)
  end

  def consume(connection \\ __MODULE__, spec) do
    GenServer.call(connection, {:consume, spec})
  end

  def handle_continue(:open_connection, state) do
    case connect(state) do
      {:ok, state} ->
        {:noreply, state}

      {:error, _error} ->
        Logger.error("Failed to connect to rabbit")

        5
        |> :timer.seconds()
        |> :timer.sleep()

        {:noreply, state, {:continue, :open_connection}}
    end
  end

  def handle_info({:DOWN, _ref, :process, _object, _reason}, state) do
    {:stop, :normal, state}
  end

  def handle_call(:publisher_channel, _from, state = %{publisher_channel: channel}) do
    {:reply, channel, state}
  end

  def handle_call(
        {:consume, spec},
        _from,
        state = %{
          consumer_channels: channels,
          connection: connection
        }
      ) do
    with {:ok, channels, channel} <-
           @stream_adapter.get_channel_from_cache(connection, channels, spec.consumer_module),
         :ok <- @stream_adapter.bind_queue(channel, spec) do
      Process.monitor(channel.pid)
      {:reply, {:ok, channel}, %{state | consumer_channels: channels}}
    else
      {:error, error} ->
        {:reply, {:error, error}, state}
    end
  end

  def terminate(_reason, %{connection: nil}) do
    {:stop, :normal}
  end

  def terminate(_reason, %{connection: connection}) do
    @stream_adapter.close_connection(connection)
    {:stop, :normal}
  end

  defp connect(state) do
    with {:ok, connection} <- @stream_adapter.connect(),
         {:ok, channel} <- @stream_adapter.get_channel(connection) do
      Process.monitor(connection.pid)
      Process.monitor(channel.pid)
      {:ok, %{state | connection: connection, publisher_channel: channel}}
    else
      {:error, _error} = e -> e
    end
  end
end
