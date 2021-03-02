defmodule RailwayIpc.Core.MessageFormat.JsonProtobuf do
  @moduledoc """
  _This is an internal module, not part of the public API._

  Messages that use the `JsonProtobuf` format have the following
  characteristics:

  * The payload s a struct that contains two attributes: `type` and
    `encoded_message`

  * The `type` attribute is the name of the Elixir module for the protobuf
    without the "Elixir" prefix and uses colon notation instead of dots

  * The `encoded_message` attribute is the protobuf in map form

  * The entire payload is then converted to JSON

  Note:
  I _think_ the reason for converting to colon notation is an artifact of
  wanting to be compatable with the Ruby version since Ruby classes use
  colon notation. -BN

  """

  alias Protobuf.JSON.Decode, as: ProtoDecode
  alias RailwayIpc.DefaultMessage

  @doc """
  Encodes the given `protobuf` by creating a JSON string with two attributes:

  * `type` -- the Protobuf module name as a string using colon notation
  * `encoded_message` -- the Protobuf converted to a map

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
    |> hydrate_protobuf_from_map()
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
    {:ok, Map.put(payload, :encoded_message, ensure_map(protobuf)), protobuf}
  end

  defp encode_message({:error, _} = error), do: error

  defp ensure_map(protobuf) do
    protobuf
    |> Map.from_struct()
    |> Map.new(fn
      {k, %_{} = struct} -> {k, ensure_map(struct)}
      {k, v} -> {k, v}
    end)
  end

  defp encode_payload_as_json({:ok, payload, _}) do
    case Jason.encode(payload) do
      {:ok, json} -> {:ok, json, payload.type}
      {:error, error} -> {:error, error}
    end
  end

  defp encode_payload_as_json({:error, _} = error), do: error

  defp type_to_module(type) do
    type
    |> String.split("::")
    |> Module.concat()
  end

  defp replace_invalid_chars(module_name_string) do
    Regex.replace(~r/\AElixir\./, module_name_string, "")
    |> String.replace(".", "::")
  end

  defp hydrate_protobuf_from_map({:error, _} = error), do: error

  defp hydrate_protobuf_from_map({status, payload}) do
    %{encoded_message: message, module: module, type: type} = payload
    decoded_message = ProtoDecode.from_json_data(message, module)
    {status, decoded_message, type}
  catch
    _error ->
      {:error, "Cannot decode protobuf"}
  end

  defp check_that_module_is_defined({:ok, payload}) do
    %{module: module} = payload
    module.__info__(:module)
    {:ok, payload}
  rescue
    UndefinedFunctionError ->
      {:unknown_message_type, Map.put(payload, :module, DefaultMessage)}
  end

  defp check_that_module_is_defined({:error, _} = error), do: error

  defp parse_type({:ok, %{type: type} = payload}) when is_binary(type) do
    {:ok, Map.merge(payload, %{module: type_to_module(type)})}
  end

  defp parse_type({:ok, %{type: type}}) when is_nil(type) do
    {:error, "Message is missing the `type` attribute"}
  end

  defp parse_type({:ok, %{type: type}}) when not is_binary(type) do
    {:error, "Message `type` attribute must be a string"}
  end

  defp parse_type({:error, _} = error), do: error

  defp decode_json(json) do
    decoded = Jason.decode!(json)
    {:ok, %{type: decoded["type"], encoded_message: decoded["encoded_message"]}}
  rescue
    Jason.DecodeError -> {:error, "Message is invalid JSON (#{json})"}
  end
end
