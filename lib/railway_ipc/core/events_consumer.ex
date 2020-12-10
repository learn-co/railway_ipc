defmodule RailwayIpc.Core.EventsConsumer do
  @moduledoc false
  require Logger
  alias RailwayIpc.Core.EventMessage
  alias RailwayIpc.Telemetry

  @message_consumption Application.get_env(
                         :railway_ipc,
                         :message_consumption,
                         RailwayIpc.MessageConsumption
                       )

  def process(payload, module, exchange, queue, ack_func) do
    Telemetry.track_process_message(
      %{payload: payload, module: module, exchange: exchange, queue: queue},
      fn ->
        result = @message_consumption.process(payload, module, exchange, queue, EventMessage)
        {result |> post_processing(ack_func), %{result: result}}
      end
    )
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
