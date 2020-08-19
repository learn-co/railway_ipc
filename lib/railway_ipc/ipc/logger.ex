defmodule RailwayIpc.Ipc.Logger do
  require Logger
  import RailwayIpc.Utils, only: [protobuf_to_map: 1]
  defdelegate debug(message), to: Logger
  defdelegate debug(message, metadata), to: Logger
  defdelegate info(message), to: Logger
  defdelegate info(message, metadata), to: Logger
  defdelegate warn(message), to: Logger
  defdelegate warn(message, metadata), to: Logger
  defdelegate error(message), to: Logger
  defdelegate error(message, metadata), to: Logger

  def metadata(metadata) when is_list(metadata) do
    metadata
    |> Logger.metadata()
  end

  def metadata(%{message: message, type: type}) do
    [
      correlation_id: message.correlation_id,
      message_type: type,
      message: protobuf_to_map(message) |> Jason.encode!()
    ]
    |> Logger.metadata()
  end

  def metadata(%{message: message}) do
    [
      correlation_id: message.correlation_id,
      message_type: type_from_protobuf(message),
      message: protobuf_to_map(message) |> Jason.encode!()
    ]
    |> Logger.metadata()
  end

  def metadata(%{command_response: message}) do
    [command_response_message: protobuf_to_map(message) |> Jason.encode!()]
    |> Logger.metadata()
  end

  def metadata(%{feature: feature, queue: queue, exchange: exchange}) do
    [
      feature: feature,
      queue: queue,
      exchange: exchange
    ]
    |> Logger.metadata()
  end

  def type_from_protobuf(message) do
    message.__struct__
    |> to_string
    |> String.replace(~r/^Elixir\./, "")
    |> String.split(".")
    |> Enum.join("::")
  end
end
