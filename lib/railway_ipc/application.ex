defmodule RailwayIpc.Application do
  @moduledoc false

  use Application
  @dev_repo Application.get_env(:railway_ipc, :dev_repo)
  def start(_type, _args) do
    opts = [strategy: :one_for_one, name: RailwayIpc.Supervisor]
    Supervisor.start_link(children(@dev_repo), opts)
  end

  def children(true) do
    [
      RailwayIpc.Dev.Repo,
      {
        RailwayIpc.Connection.Supervisor,
        [RailwayIpc.Ipc.RepublishedMessagesConsumer]
      }
    ]
  end

  def children(_), do: []
    # do: [
    #   {
    #     RailwayIpc.Connection.Supervisor,
    #     [RailwayIpc.Ipc.RepublishedMessagesConsumer]
    #   }
    # ]
end
