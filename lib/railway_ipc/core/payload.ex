defmodule RailwayIpc.Core.Payload do
  @moduledoc """
  _This is an internal module, not part of the public API._

  Handles encoding/decoding of messages by delegating to specific message
  format helper modules.

  """

  alias RailwayIpc.Core.MessageFormat.BinaryProtobuf
  alias RailwayIpc.Core.MessageFormat.JsonProtobuf

  def decode(payload, message_format \\ nil) do
    get_formatter(message_format).decode(payload)
  end

  def encode(protobuf_struct) do
    BinaryProtobuf.encode(protobuf_struct)
  end

  defp get_formatter(message_format) do
    case message_format do
      "binary_protobuf" -> BinaryProtobuf
      "json_protobuf" -> JsonProtobuf
      _ -> BinaryProtobuf
    end
  end
end
