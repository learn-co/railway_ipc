defmodule RailwayIpc.Ipc.RepublishedMessagesConsumer do
  use RailwayIpc.CommandsConsumer,
    queue: "railway_ipc:republished_messages:commands"

  def handle_in(_payload) do
    # get persisted published message from payload
    # re-publish it in such a way as to skip persistence
    #  Question: where does that re-publishing logic go?
    #    Right now its in `RailwayIpc.Publisher`
    IO.puts("CONSUMING REPUBLISHED MESSAGE COMMAND...")
    :ok
  end
end
