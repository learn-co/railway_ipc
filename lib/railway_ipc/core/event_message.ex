defmodule RailwayIpc.Core.EventMessage do
  defstruct ~w[encoded_message decoded_message type]a

  alias RailwayIpc.Core.Payload

  def new(%{
        payload: payload
      }) do
    %__MODULE__{encoded_message: payload}
    |> decode()
  end

  def decode(%{encoded_message: encoded_message} = command_message) do
    case Payload.decode(encoded_message) do
      {:ok, decoded_message, type} ->
        message = update(command_message, %{decoded_message: decoded_message, type: type})
        {:ok, message}

      {:unknown_message_type, decoded_message, type} ->
        message = update(command_message, %{decoded_message: decoded_message, type: type})
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
