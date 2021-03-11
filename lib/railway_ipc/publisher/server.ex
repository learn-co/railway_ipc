defmodule RailwayIpc.Publisher.Server do
  @moduledoc """
  Maintains state of publishers (i.e. connection, channel, etc.).

  _This is an internal module, not part of the public API._

  """

  use GenServer

  alias RailwayIpc.MessageBus.Publisher
  alias RailwayIpc.Publisher.Telemetry

  defstruct [:adapter, :channel, :connection]

  @doc false
  @impl GenServer
  def init(%__MODULE__{} = state) do
    Process.flag(:trap_exit, true)
    {:ok, state, {:continue, :open_connection}}
  end

  @doc false
  @impl GenServer
  def handle_continue(:open_connection, %__MODULE__{} = state) do
    {:noreply, Map.merge(state, open(state))}
  end

  @doc false
  @impl GenServer
  def handle_call({:publish, exchange, payload, format}, _from, %__MODULE__{} = state) do
    %{adapter: adapter, channel: channel} = state

    case adapter.publish(channel, exchange, payload, format) do
      {:ok, _} -> {:reply, :ok, state}
      {:error, error} -> {:reply, {:error, error}, state}
    end
  end

  @doc false
  @impl GenServer
  def handle_info({:DOWN, _ref, :process, _pid, reason}, %__MODULE__{} = state) do
    Telemetry.emit_publisher_down(__MODULE__, reason)
    close(state)
    {:noreply, Map.merge(state, open(state))}
  end

  @doc false
  @impl GenServer
  def terminate(reason, %__MODULE__{} = state) do
    Telemetry.emit_publisher_terminate(__MODULE__, reason)
    close(state)
    :normal
  end

  defp open(state) do
    %{adapter: adapter} = state
    {:ok, %Publisher{connection: connection, channel: channel}} = adapter.setup_publisher()

    if connection, do: Process.monitor(connection.pid)
    if channel, do: Process.monitor(channel.pid)
    %{connection: connection, channel: channel}
  end

  defp close(state) do
    %{adapter: adapter, connection: connection, channel: channel} = state
    adapter.cleanup_publisher(%Publisher{connection: connection, channel: channel})
  end
end
