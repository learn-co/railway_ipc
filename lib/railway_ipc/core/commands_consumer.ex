defmodule RailwayIpc.Core.CommandsConsumer do
  @moduledoc false
  require Logger
  alias RailwayIpc.Core.CommandMessage

  @message_consumption Application.get_env(
                         :railway_ipc,
                         :message_consumption,
                         RailwayIpc.MessageConsumption
                       )

  def process(payload, module, exchange, queue, ack_func, publish_func) do
    @message_consumption.process(payload, module, exchange, queue, CommandMessage)
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

  def post_processing(
        {:error, %{result: %{reason: reason}, payload: payload}},
        ack_func,
        _publish_func
      ) do
    Logger.error("Failed to process message #{payload}, error #{reason}")
    ack_func.()
  end

  def post_processing(
        {:skip, %{result: %{reason: reason}, payload: payload}},
        ack_func,
        _publish_func
      ) do
    Logger.info("Skipping handling for message #{payload}, reason #{reason}")
    ack_func.()
  end
end
