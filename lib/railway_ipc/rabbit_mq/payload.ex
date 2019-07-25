defmodule RailwayIpc.RabbitMQ.Payload do
  @behaviour RailwayIpc.PayloadBehaviour
  import RailwayIpc.Utils, only: [module_defined?: 1]

  def decode(payload) when not is_binary(payload) do
    {:error, "Malformed JSON given: #{payload}. Must be a string"}
  end

  def decode(payload) do
    with {:decode_json, {:ok, %{"type" => type, "encoded_message" => encoded_message}}} <- {
      :decode_json,
      Jason.decode(payload)
    },
         {:convert_module, module} <- {:convert_module, module_from_type(type)},
         {:check_module_exists, true} <- {:check_module_exists, module_defined?(module)},
         {:decode_message, message} <- {:decode_message, decode_message(module, encoded_message)} do
      {:ok, message}
    else
      {:decode_json, {:ok, _}} ->
        {:error, "Missing keys: #{payload}. Expecting type and encoded_message keys"}
      {:decode_json, {:error, _}} ->
        {:error, "Malformed JSON given: #{payload}"}
      {:check_module_exists, false} ->
        %{"type" => type} = Jason.decode!(payload)
        {:error, "Unknown message type #{type}"}
    end
  end

  def encode(protobuf_struct) do
    {
      :ok,
      %{
        type: encode_type(protobuf_struct),
        encoded_message: encode_message(protobuf_struct)
      }
      |> Jason.encode!
    }
  end

  def encode_message(protobuf_struct) do
    protobuf_struct
    |> protobuf_struct.__struct__.encode
    |> Base.encode64
  end

  def encode_type(protobuf_struct) do
    module = protobuf_struct.__struct__
    module_name = module
                  |> to_string
    Regex.replace(~r/\AElixir\./, module_name, "")
    |> String.replace(".", "::")
  end

  def module_from_type(type) do
    type
    |> String.split("::")
    |> Module.concat
  end

  def decode_message(module, encoded_message) do
    encoded_message
    |> Base.decode64!
    |> module.decode
  end
end

