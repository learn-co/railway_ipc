defmodule RailwayIpc.MessagePublishing do
  @persistence Application.get_env(:railway_ipc, :persistence)

  def process(message, exchange) do
    @persistence.insert_published_message(message, exchange)
  end
end
