defmodule RailwayIpc.Core.CommandMessage do
  alias RailwayIpc.Core.Payload

  defstruct ~w[encoded_message decoded_message]a

  def new(%{
        payload: payload
      }) do
    %__MODULE__{encoded_message: payload}
    |> decode()
  end

  def decode(%{encoded_message: encoded_message} = command_message) do
    case Payload.decode(encoded_message) do
      {:ok, decoded_message} ->
        message = update(command_message, %{decoded_message: decoded_message})
        {:ok, message}

      {:error, error} ->
        {:error, error}
    end
  end

  def update(consumed_message, attrs) do
    consumed_message
    |> Map.merge(attrs)
  end
end
