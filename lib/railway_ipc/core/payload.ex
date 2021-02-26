defmodule RailwayIpc.Core.Payload do
  @moduledoc """
  Handles encoding/decoding of messages by delegating to specific message
  format helper modules.

  _This is an internal module, not part of the public API._

  """

  alias RailwayIpc.Core.MessageFormat.BinaryProtobuf
  alias RailwayIpc.Core.MessageFormat.JsonProtobuf

  @doc """
  Takes a `payload` and decodes it using the specified `message_format`. If
  a message format is not provided, the default format (`BinaryProtobuf`)
  is used.

  """
  def decode(payload, message_format \\ nil) do
    get_formatter(message_format).decode(payload)
  end

  @doc """
  Takes a `protobuf` and prepares it for publishing by encoding it in the
  given `message_format`. If a message format is not provided, the default
  format (`BinaryProtobuf`) is used.

  Encoded messages require that a protobuf has a UUID. If the given protobuf
  does not provide a UUID, one will be generated. We currently use `Ecto.UUID`
  to generate the protobuf UUID. We are investigating using `UUID.uuid4`
  instead so that we're not coupled to Ecto at this level.

  """
  def encode(protobuf, message_format \\ nil) do
    protobuf
    |> ensure_uuid()
    |> get_formatter(message_format).encode()
  end

  defp ensure_uuid(%{uuid: uuid} = message) when is_nil(uuid) or "" == uuid do
    # TODO: Do we really want to couple this to Ecto? Would UUID.uuid4() be
    # more appropriate?
    Map.put(message, :uuid, Ecto.UUID.generate())
  end

  defp ensure_uuid(message), do: message

  defp get_formatter(message_format) do
    case message_format do
      "binary_protobuf" -> BinaryProtobuf
      "json_protobuf" -> JsonProtobuf
      _ -> BinaryProtobuf
    end
  end
end
