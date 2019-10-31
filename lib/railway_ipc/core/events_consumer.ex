defmodule RailwayIpc.Core.EventsConsumer do
  require Logger
  alias RailwayIpc.Core.EventMessage
  @railway_ipc Application.get_env(:railway_ipc, :railway_ipc, RailwayIpc)

  def process(payload, module, exchange, queue, ack_func) do
    @railway_ipc.process_consumed_message(payload, module, exchange, queue, EventMessage)
    |> post_processing(ack_func)
  end

  def post_processing({:ok, _message_consumption}, ack_func) do
    ack_func.()
  end

  def post_processing({:error, %{result: %{reason: reason}, payload: payload}}, ack_func) do
    Logger.error("Failed to process message #{payload}, error #{reason}")
    ack_func.()
  end

  def post_processing({:skip, %{result: %{reason: reason}, payload: payload}}, ack_func) do
    Logger.info("Skipping handling for message: #{payload}, reason: #{reason}")
    ack_func.()
  end
end
