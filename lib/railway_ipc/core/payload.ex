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

  # FIXME: This should really be returned as part of the #encode function
  # result for two reasons:
  #
  # 1) It duplicates the type encoding logic
  # 2) It tightly couples this Payload module to modules that otherwise
  #    wouldn't need it
  def encode_type(protobuf_struct) do
    module = protobuf_struct.__struct__

    module_name =
      module
      |> to_string

    Regex.replace(~r/\AElixir\./, module_name, "")
    |> String.replace(".", "::")
  end

  defp get_formatter(message_format) do
    case message_format do
      "binary_protobuf" -> BinaryProtobuf
      "json_protobuf" -> JsonProtobuf
      _ -> BinaryProtobuf
    end
  end
end
