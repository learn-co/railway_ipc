defmodule RailwayIpc.Connection do
  @moduledoc false
  @stream_adapter Application.get_env(
                    :railway_ipc,
                    :stream_adapter,
                    RailwayIpc.RabbitMQ.RabbitMQAdapter
                  )

  defstruct connection: nil,
            consumer_channels: %{}

  use GenServer
  require Logger
  alias RailwayIpc.Telemetry

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    {:ok, %__MODULE__{}, {:continue, :open_connection}}
  end

  def consume(connection \\ __MODULE__, spec) do
    GenServer.call(connection, {:consume, spec})
  end

  def handle_continue(:open_connection, state) do
    Telemetry.track_opening_connection(fn ->
      case connect(state) do
        {:ok, state} ->
          {{:noreply, state}, %{state: state}}

        {:error, reason} ->
          Logger.error("Failed to connect to rabbit")

          5
          |> :timer.seconds()
          |> :timer.sleep()

          {{:noreply, state, {:continue, :open_connection}},
           %{error: "Failed to connect to rabbit. Trying again", reason: reason}}
      end
    end)
  end

  def handle_info({:DOWN, _ref, :process, _object, _reason}, state) do
    {:stop, :normal, state}
  end

  def handle_call(
        {:consume, spec},
        _from,
        %{
          consumer_channels: channels,
          connection: connection
        } = state
      ) do
    Telemetry.track_adding_consumer(
      %{spec: spec},
      fn ->
        with {:ok, channels, channel} <-
               @stream_adapter.get_channel_from_cache(connection, channels, spec.consumer_module),
             :ok <- @stream_adapter.bind_queue(channel, spec) do
          Process.monitor(channel.pid)
          {{:reply, {:ok, channel}, %{state | consumer_channels: channels}}, %{}}
        else
          {:error, reason} ->
            {{:reply, {:error, reason}, state},
             %{error: "Failed to add consumer", reason: reason}}
        end
      end
    )
  end

  def terminate(_reason, %{connection: nil}) do
    {:stop, :normal}
  end

  def terminate(_reason, %{connection: connection}) do
    @stream_adapter.close_connection(connection)
    {:stop, :normal}
  end

  defp connect(state) do
    case @stream_adapter.connect() do
      {:ok, connection} ->
        Process.monitor(connection.pid)
        {:ok, %{state | connection: connection}}

      {:error, _error} = e ->
        e
    end
  end
end
