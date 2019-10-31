defmodule RailwayIpc do
  alias RailwayIpc.MessageConsumption
  alias RailwayIpc.MessagePublishing
  @behaviour RailwayIpcBehaviour

  def process_published_message(message, exchange) do
    MessagePublishing.process(message, exchange)
  end

  def process_consumed_message(payload, handle_module, exchange, queue, message_module) do
    MessageConsumption.process(payload, handle_module, exchange, queue, message_module)
  end
end
