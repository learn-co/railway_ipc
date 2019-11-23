defmodule RailwayIpc.Application do
  @moduledoc false

  use Application
  @dev_repo Application.get_env(:railway_ipc, :dev_repo)
  def start(_type, _args) do
    opts = [strategy: :one_for_one, name: RailwayIpc.Supervisor]
    Supervisor.start_link(children(@dev_repo, Mix.env()), opts)
  end

  def children(true, :dev) do
    [
      RailwayIpc.Dev.Repo,
      {
        RailwayIpc.Connection.Supervisor,
        [RailwayIpc.Ipc.RepublishedMessagesConsumer]
      }
    ]
  end

  def children(true, :test) do
    [RailwayIpc.Dev.Repo]
  end

  def children(nil, _),
    do: [
      {
        RailwayIpc.Connection.Supervisor,
        [RailwayIpc.Ipc.RepublishedMessagesConsumer]
      }
    ]
end
