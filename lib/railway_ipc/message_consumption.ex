defmodule RailwayIpc.MessageConsumption do
  alias RailwayIpc.Core.{CommandMessage, EventMessage}
  alias RailwayIpc.Core.MessageConsumptionResult, as: Result
  alias RailwayIpc.CommandMessageHandler
  alias RailwayIpc.ConsumedMessage, as: ConsumedMessageContext
  require Logger

  @behaviour RailwayIpc.MessageConsumptionBehaviour

  defstruct [
    :payload,
    :handle_module,
    :exchange,
    :queue,
    :inbound_message,
    :outbound_message,
    :persisted_message,
    :result
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
        handle_decode_success(message_consumption, message)

      {:unknown_message_type, %{type: type} = message} ->
        handle_unknown_message_type(message_consumption, message, type)

      {:error, error} ->
        handle_decode_failure(message_consumption, error)
    end
  end

  def do_decode_message(message_consumption, message_module) do
    message_module.new(message_consumption)
  end

  def persist_message({:ok, message_consumption}) do
    case ConsumedMessageContext.create(message_consumption) do
      {:ok, persisted_message} ->
        handle_persistence_success(message_consumption, persisted_message)

      {status, _reason} = result ->
        {status, update(message_consumption, %{result: Result.new(result)})}
    end
  end

  def persist_message({:skip, message_consumption}) do
    case ConsumedMessageContext.create(message_consumption) do
      {:ok, persisted_message} ->
        {:skip, update(message_consumption, %{persisted_message: persisted_message})}

      {status, _reason} = result ->
        {status, update(message_consumption, %{result: Result.new(result)})}
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
        handle_processed_success(message_consumption, persisted_message)

      {:error, _error} = result ->
        handle_error(message_consumption, result)
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
        handle_processed_success(message_consumption, persisted_message)

      {:emit, event} ->
        {:emit,
         update(message_consumption, %{
           result: Result.new(%{status: :handled}),
           persisted_message: mark_persisted_message_handled(persisted_message),
           outbound_message: event
         })}

      {:error, _error} = result ->
        handle_error(message_consumption, result)
    end
  end

  def handle_message({status, message_consumption}) do
    {status, message_consumption}
  end

  defp update(message_consumption, attrs) do
    message_consumption
    |> Map.merge(attrs)
  end

  defp mark_persisted_message_handled(persisted_message) do
    ConsumedMessageContext.consumed_message_success(persisted_message)
  end

  defp handle_decode_success(message_consumption, inbound_message) do
    {:ok, update(message_consumption, %{inbound_message: inbound_message})}
  end

  defp handle_unknown_message_type(message_consumption, inbound_message, type) do
    {:skip,
     update(message_consumption, %{
       inbound_message: inbound_message,
       result: Result.new(%{status: :skip, reason: "Unknown message of type: #{type}"})
     })}
  end

  defp handle_decode_failure(message_consumption, error) do
    {:error, update(message_consumption, %{result: Result.new(%{status: :error, reason: error})})}
  end

  defp handle_persistence_success(message_consumption, persisted_message) do
    {:ok, update(message_consumption, %{persisted_message: persisted_message})}
  end

  defp handle_processed_success(message_consumption, persisted_message) do
    {:ok,
     update(message_consumption, %{
       result: Result.new(%{status: :handled}),
       persisted_message: mark_persisted_message_handled(persisted_message)
     })}
  end

  defp handle_error(message_consumption, result) do
    {:error, update(message_consumption, %{result: Result.new(result)})}
  end
end
