defmodule RailwayIpc.Core.MessageFormat.BinaryProtobuf do
  @moduledoc """
  _This is an internal module, not part of the public API._

  Messages that use the `BinaryProtobuf` format have the following
  characteristics:

  * The payload s a struct that contains two attributes: `type` and
    `encoded_message`

  * The `type` attribute is the name of the Elixir module for the protobuf
    without the "Elixir" prefix and to use colon notation instead of dots.

  * The `encoded_message` attribute is the encoded protobuf which is then
    Base64 encoded to make it friendly to JSON conversion.

  * The entire payload is then converted to JSON.

  Note:
  I _think_ the reason for converting to colon notation is an artifact of
  wanting to be compatable with the Ruby version since Ruby classes use
  colon notation. -BN

  """

  alias RailwayIpc.DefaultMessage

  @doc """
  Encodes `protobuf` in message format. Returns the encoded protobuf and the
  message type as a string in colon format.

  Encodes the given `protobuf` by creating a JSON string with two attributes:

  * `type` -- the Protobuf module name as a string using colon notation
  * `encoded_message` -- the Base64 encoded Protobuf

  """
  def encode(protobuf) when is_map(protobuf) or is_atom(protobuf) do
    protobuf
    |> build_payload()
    |> encode_type()
    |> encode_message()
    |> encode_payload_as_json()
  end

  def encode(_), do: {:error, "Argument Error: Valid Protobuf required"}

  @doc """
  Decodes the given `message` into a Protobuf `struct`.

  """
  def decode(message) when not is_binary(message) do
    {:error, "Malformed JSON given. Must be a string. (#{inspect(message)})"}
  end

  def decode(message) do
    message
    |> decode_json()
    |> parse_type()
    |> check_that_module_is_defined()
    |> decode_protobuf()
  end

  defp build_payload(protobuf), do: {:ok, %{}, protobuf}

  defp encode_type({:ok, payload, protobuf}) do
    type =
      protobuf.__struct__
      |> to_string
      |> replace_invalid_chars()

    {:ok, Map.put(payload, :type, type), protobuf}
  rescue
    KeyError ->
      {:error, "Argument Error: Valid Protobuf required"}
  end

  defp encode_message({:ok, payload, protobuf}) do
    encoded_message =
      protobuf
      |> protobuf.__struct__.encode()
      |> Base.encode64()

    {:ok, Map.put(payload, :encoded_message, encoded_message), protobuf}
  end

  defp encode_message({:error, _} = error), do: error

  defp encode_payload_as_json({:ok, payload, _}) do
    case Jason.encode(payload) do
      {:ok, json} -> {:ok, json, payload.type}
      {:error, error} -> {:error, error}
    end
  end

  defp encode_payload_as_json({:error, _} = error), do: error

  defp parse_type({:ok, %{type: type} = payload}) when is_binary(type) do
    {:ok, Map.put(payload, :module, type_to_module(type))}
  end

  defp parse_type({:ok, %{type: type}}) when not is_binary(type) do
    {:error, "Message `type` attribute must be a string"}
  end

  defp parse_type({:ok, _}), do: {:error, "Message is missing the `type` attribute"}
  defp parse_type({:error, _} = error), do: error

  defp check_that_module_is_defined({:ok, payload}) do
    %{module: module} = payload
    module.__info__(:module)
    {:ok, payload}
  rescue
    UndefinedFunctionError ->
      {:unknown_message_type, Map.put(payload, :module, DefaultMessage)}
  end

  defp check_that_module_is_defined({:error, _} = error), do: error

  defp decode_protobuf({:error, _} = error), do: error

  defp decode_protobuf({status, payload}) do
    %{module: module, encoded_message: encoded_message, type: type} = payload

    decoded_message =
      encoded_message
      |> Base.decode64!(ignore: :whitespace)
      |> module.decode

    {status, decoded_message, type}
  rescue
    # TODO: What's the specific error we should rescue here? Can't find
    # it in the protobuf docs
    _ -> {:error, "Cannot decode protobuf"}
  end

  defp type_to_module(type) do
    type
    |> String.split("::")
    |> Module.concat()
  end

  defp replace_invalid_chars(module_name_string) do
    Regex.replace(~r/\AElixir\./, module_name_string, "")
    |> String.replace(".", "::")
  end

  defp decode_json(json) do
    {:ok, Jason.decode!(json, keys: :atoms)}
  rescue
    Jason.DecodeError -> {:error, "Message is invalid JSON (#{json})"}
  end
end
