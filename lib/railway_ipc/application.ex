defmodule RailwayIpc.Application do
  @moduledoc false

  use Application
  @use_dev_repo Application.get_env(:railway_ipc, :dev_repo)
  @repo Application.get_env(:railway_ipc, :repo, RailwayIpc.Dev.Repo)

  def start(_type, _args) do
    opts = [strategy: :one_for_one, name: RailwayIpc.Supervisor]
    Supervisor.start_link(children(@use_dev_repo, Mix.env()), opts)
  end

  def children(true, :dev) do
    [
      @repo,
      {RailwayIpc.Connection.Supervisor, []}
    ]
  end

  def children(_, :dev) do
    [
      {RailwayIpc.Connection.Supervisor, []}
    ]
  end

  def children(true, :test) do
    [
      @repo
    ]
  end

  def children(_, _), do: []
end
