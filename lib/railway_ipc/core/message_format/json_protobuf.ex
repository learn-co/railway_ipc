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
    encoded_message = protobuf |> Map.from_struct()
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
    %{module: module, encoded_message: message, type: type} = payload
    decoded_message = message |> module.new()
    stringified_context = stringify_keys(decoded_message.context)
    {status, Map.put(decoded_message, :context, stringified_context), type}
  rescue
    Protocol.UndefinedError ->
      {:error, "Cannot decode protobuf"}
  end

  defp stringify_keys(nil), do: nil

  defp stringify_keys(%{} = map) do
    map
    |> Enum.map(fn {k, v} -> {Atom.to_string(k), stringify_keys(v)} end)
    |> Enum.into(%{})
  end

  defp stringify_keys([head | rest]) do
    [stringify_keys(head) | stringify_keys(rest)]
  end

  defp stringify_keys(not_a_map) do
    not_a_map
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
    {:ok, Map.put(payload, :module, type_to_module(type))}
  end

  defp parse_type({:ok, %{type: type}}) when not is_binary(type) do
    {:error, "Message `type` attribute must be a string"}
  end

  defp parse_type({:ok, _}), do: {:error, "Message is missing the `type` attribute"}
  defp parse_type({:error, _} = error), do: error

  defp decode_json(json) do
    {:ok, Jason.decode!(json, keys: :atoms)}
  rescue
    Jason.DecodeError -> {:error, "Message is invalid JSON (#{json})"}
  end
end
