defmodule RailwayIpc.MessagePublishing do
  alias RailwayIpc.Core.MessageAccess

  def process(message, exchange, queue) do
    MessageAccess.persist_published_message(message, exchange, queue)
  end
end
