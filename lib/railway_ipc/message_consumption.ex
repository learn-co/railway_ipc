defmodule RailwayIpc.MessageConsumption do
  @moduledoc false
  alias RailwayIpc.ConsumedMessage, as: ConsumedMessageContext
  alias RailwayIpc.Core.EventMessage
  alias RailwayIpc.Core.MessageConsumptionResult, as: Result
  alias RailwayIpc.Telemetry

  @repo Application.get_env(:railway_ipc, :repo, RailwayIpc.Dev.Repo)

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

  def process(payload, handle_module, exchange, queue) do
    {:ok, result} =
      @repo.transaction(fn ->
        new(payload, handle_module, exchange, queue)
        |> decode_message()
        |> persist_message()
        |> handle_message()
      end)

    result
  rescue
    e in Postgrex.Error ->
      if lock_error?(e) do
        {:ignore, "Message is already being processed"}
      else
        reraise(e, __STACKTRACE__)
      end
  end

  defp lock_error?(%{postgres: %{code: :lock_not_available}}), do: true
  defp lock_error?(_), do: false

  def new(payload, handle_module, exchange, queue) do
    {:ok,
     %__MODULE__{payload: payload, handle_module: handle_module, exchange: exchange, queue: queue}}
  end

  def decode_message({:ok, message_consumption}) do
    Telemetry.track_decode(%{state: message_consumption}, fn ->
      case do_decode_message(message_consumption) do
        {:ok, message} ->
          {handle_decode_success(message_consumption, message),
           %{state: message_consumption, message: message}}

        {:unknown_message_type, %{type: type} = message} ->
          {handle_unknown_message_type(message_consumption, message, type),
           %{
             state: message_consumption,
             error: :unknown_message_type,
             type: type,
             message: message
           }}

        {:error, error} ->
          {handle_decode_failure(message_consumption, error),
           %{state: message_consumption, error: error}}
      end
    end)
  end

  def do_decode_message(message_consumption) do
    EventMessage.new(message_consumption)
  end

  def persist_message({:ok, message_consumption}) do
    Telemetry.track_persist(%{state: message_consumption}, fn ->
      case ConsumedMessageContext.find_or_create(message_consumption) do
        {:ok, persisted_message} ->
          {handle_persistence_success(message_consumption, persisted_message),
           %{state: message_consumption, persisted_message: persisted_message}}

        {status, reason} = result ->
          {{status, update(message_consumption, %{result: Result.new(result)})},
           %{state: message_consumption, error: "Failed to Persist", reason: reason}}
      end
    end)
  end

  def persist_message({:skip, message_consumption}) do
    Telemetry.track_persist(%{state: message_consumption}, fn ->
      case ConsumedMessageContext.find_or_create(message_consumption) do
        {:ok, persisted_message} ->
          {{:skip, update(message_consumption, %{persisted_message: persisted_message})},
           %{state: message_consumption, persisted_message: persisted_message, skip: true}}

        {status, reason} = result ->
          {{status, update(message_consumption, %{result: Result.new(result)})},
           %{state: message_consumption, error: "Failed to Persist", reason: reason}}
      end
    end)
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
    Telemetry.track_handle_message(
      %{decoded_message: decoded_message, consumer_type: :event},
      fn ->
        case handle_module.handle_in(decoded_message) do
          :ok ->
            {handle_processed_success(message_consumption, persisted_message),
             %{state: message_consumption, decoded_message: decoded_message}}

          {:error, reason} = result ->
            {handle_error(message_consumption, result),
             %{state: message_consumption, error: "Failed to handle Event", reason: reason}}
        end
      end
    )
  end

  def handle_message({:error, message_consumption}) do
    {:error, message_consumption}
  end

  def handle_message({:ignore, message_consumption}), do: {:skip, message_consumption}

  def handle_message(
        {_processing_status,
         %{
           persisted_message: persisted_message,
           result: %{
             status: result_status
           }
         } = message_consumption}
      ) do
    {:skip,
     update(message_consumption, %{
       persisted_message: update_persisted_message_status(persisted_message, result_status)
     })}
  end

  defp update(message_consumption, attrs) do
    message_consumption
    |> Map.merge(attrs)
  end

  defp mark_persisted_message_handled(persisted_message) do
    ConsumedMessageContext.consumed_message_success(persisted_message)
  end

  defp update_persisted_message_status(persisted_message, status) do
    ConsumedMessageContext.update_status(persisted_message, status)
  end

  defp handle_decode_success(message_consumption, inbound_message) do
    {:ok, update(message_consumption, %{inbound_message: inbound_message})}
  end

  defp handle_unknown_message_type(message_consumption, inbound_message, type) do
    {:skip,
     update(message_consumption, %{
       inbound_message: inbound_message,
       result:
         Result.new(%{status: :unknown_message_type, reason: "Unknown message of type: #{type}"})
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
