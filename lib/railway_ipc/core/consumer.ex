defmodule RailwayIpc.Core.Consumer do
  require Logger
  @payload_converter Application.get_env(
                       :railway_ipc,
                       :payload_converter,
                       RailwayIpc.RabbitMQ.Payload
                     )

  def process(payload, module, ack_func, reply_func) do
    case @payload_converter.decode(payload) do
      {:ok, message} ->
        message
        |> module.handle_in
        |> post_processing(message, ack_func, reply_func)
      {:error, error} ->
        Logger.error("Failed to process message #{payload}, error #{error}")
        ack_func.()
    end
  end

  def post_processing(:ok, _message, ack_func, _reply_func) do
    ack_func.()
  end

  def post_processing({:reply, reply}, %{reply_to: reply_to}, ack_func, reply_func) do
    {:ok, reply} = @payload_converter.encode(reply)
    reply_func.(reply_to, reply)
    ack_func.()
  end

  def post_processing({:error, error}, _message, ack_func, _reply_func) do
    Logger.error("Failed to process message, error #{error}")
    ack_func.()
  end
end
