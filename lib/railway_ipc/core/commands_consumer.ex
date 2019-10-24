defmodule RailwayIpc.Core.CommandsConsumer do
  require Logger
  alias RailwayIpc.Core.CommandMessage
  @railway_ipc Application.get_env(:railway_ipc, :railway_ipc)

  def process(payload, module, exchange, queue, ack_func, publish_func) do
    @railway_ipc.process_consumed_message(payload, module, exchange, queue, CommandMessage)
    |> post_processing(ack_func, publish_func)
  end

  def post_processing({:ok, _message_consumption}, ack_func, _publish_func) do
    ack_func.()
  end

  def post_processing(
        {:emit, %{outbound_message: event}},
        ack_func,
        publish_func
      ) do
    publish_func.(event)
    ack_func.()
  end

  def post_processing({:error, %{error: error, payload: payload}}, ack_func, _publish_func) do
    Logger.error("Failed to process message #{payload}, error #{error}")
    ack_func.()
  end

  def post_processing({:skip, %{skip_reason: reason, payload: payload}}, ack_func) do
    Logger.info("Skipping handling for message #{payload}, reason #{reason}")
    ack_func.()
  end
end
