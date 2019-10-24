defmodule RailwayIpc.MessageConsumption do
  alias RailwayIpc.Core.CommandMessage
  alias RailwayIpc.Core.EventMessage
  alias RailwayIpc.CommandMessageHandler
  alias RailwayIpc.Core.MessageAccess
  require Logger

  defstruct [
    :payload,
    :handle_module,
    :exchange,
    :queue,
    :inbound_message,
    :outbound_message,
    :persisted_message,
    :handled,
    :error,
    :skip_reason
  ]

  def process(payload, handle_module, exchange, queue, message_module) do
    new(payload, handle_module, exchange, queue)
    |> decode_message(message_module)
    |> persist_message()
    |> handle_message()
  end

  def new(payload, handle_module, exchange, queue) do
    {:ok,
     %__MODULE__{payload: payload, handle_module: handle_module, exchange: exchange, queue: queue}}
  end

  def decode_message({:ok, message_consumption}, message_module) do
    case do_decode_message(message_consumption, message_module) do
      {:ok, message} ->
        {:ok, update(message_consumption, %{inbound_message: message})}

      {:error, error} ->
        {:error, update(message_consumption, %{error: error})}
    end
  end

  def decode_message({:error, message_consumption}, _message_module) do
    {:error, message_consumption}
  end

  def do_decode_message(message_consumption, message_module) do
    message_module.new(message_consumption)
  end

  def persist_message({:ok, message_consumption}) do
    case MessageAccess.persist_consumed_message(message_consumption) do
      {:ok, persisted_message} ->
        {:ok, update(message_consumption, %{persisted_message: persisted_message})}
      {:skip, reason} ->
        {:skip, update(message_consumption, %{skip_reason: reason})}
      {:error, error} ->
        {:error, update(message_consumption, %{error: error})}
    end
  end

  def persist_message({:error, message_consumption}) do
    {:error, message_consumption}
  end

  def handle_message(
        {:ok,
         %{
           inbound_message: %{decoded_message: decoded_message} = %EventMessage{},
           handle_module: handle_module,
           persisted_message: persisted_message
         } = message_consumption}
      ) do
    case handle_module.handle_in(decoded_message) do
      :ok ->
        {:ok,
         update(message_consumption, %{
           handled: true,
           persisted_message: mark_persisted_message_handled(persisted_message)
         })}

      {:error, error} ->
        {:error, update(message_consumption, %{error: error})}
    end
  end

  def handle_message(
        {:ok,
         %{
           inbound_message: %{decoded_message: decoded_message} = %CommandMessage{},
           handle_module: handle_module,
           persisted_message: persisted_message
         } = message_consumption}
      ) do
    case CommandMessageHandler.handle_message(decoded_message, handle_module) do
      :ok ->
        {:ok,
         update(message_consumption, %{
           handled: true,
           persisted_message: mark_persisted_message_handled(persisted_message)
         })}

      {:emit, event} ->
        {:emit,
         update(message_consumption, %{
           handled: true,
           persisted_message: mark_persisted_message_handled(persisted_message),
           outbound_message: event
         })}

      {:error, error} ->
        {:error, update(message_consumption, %{error: error})}
    end
  end

  def handle_message({:error, message_consumption}) do
    {:error, message_consumption}
  end

  def handle_message({:skip, message_consumption}) do
    {:skip, message_consumption}
  end

  defp update(message_consumption, attrs) do
    message_consumption
    |> Map.merge(attrs)
  end

  defp mark_persisted_message_handled(persisted_message) do
    MessageAccess.consumed_message_success(persisted_message)
  end
end
