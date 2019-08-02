defmodule RailwayIpc.Core.EventsConsumer do
  require Logger
  alias RailwayIpc.Core.Payload

  def process(payload, module, ack_func) do
    case Payload.decode(payload) do
      {:ok, message} ->
        message
        |> module.handle_in
        |> post_processing(message, ack_func)

      {:error, error} ->
        Logger.error("Failed to process message #{payload}, error #{error}")
        ack_func.()
    end
  end

  def post_processing(:ok, _message, ack_func) do
    ack_func.()
  end

  def post_processing({:error, error}, _message, ack_func) do
    Logger.error("Failed to process message, error #{error}")
    ack_func.()
  end
end
