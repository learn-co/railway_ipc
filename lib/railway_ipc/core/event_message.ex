defmodule RailwayIpc.Core.EventMessage do
  @moduledoc false
  defstruct ~w[encoded_message decoded_message type]a

  alias RailwayIpc.Core.Payload

  def new(%{payload: payload}, message_format \\ nil) do
    %__MODULE__{encoded_message: payload}
    |> decode(message_format)
  end

  def decode(%{encoded_message: encoded_message} = event_message, message_format) do
    case Payload.decode(encoded_message, message_format) do
      {:ok, decoded_message} ->
        message = update(event_message, %{decoded_message: decoded_message})
        {:ok, message}

      {:unknown_message_type, decoded_message, type} ->
        message = update(event_message, %{decoded_message: decoded_message, type: type})
        {:unknown_message_type, message}

      {:error, error} ->
        {:error, error}
    end
  end

  def update(consumed_message, attrs) do
    consumed_message
    |> Map.merge(attrs)
  end
end
