defmodule RailwayIpc.Application do
  @moduledoc false

  use Application
  @use_dev_repo Application.get_env(:railway_ipc, :dev_repo)
  @repo Application.get_env(:railway_ipc, :repo, RailwayIpc.Dev.Repo)
  @start_supervisor Application.get_env(:railway_ipc, :start_supervisor)
  @mix_env Application.get_env(:railway_ipc, :mix_env, :prod)

  def start(_type, _args) do
    :logger.add_primary_filter(
      :ignore_rabbitmq_progress_reports,
      {&:logger_filters.domain/2, {:stop, :equal, [:progress]}}
    )

    opts = [strategy: :one_for_one, name: RailwayIpc.Supervisor]
    Supervisor.start_link(children(@use_dev_repo, @start_supervisor, @mix_env), opts)
  end

  def children(true, true, :dev) do
    [
      @repo,
      {RailwayIpc.Connection.Supervisor, []}
    ]
  end

  def children(_, true, :dev) do
    [
      {RailwayIpc.Connection.Supervisor, []}
    ]
  end

  def children(_, _, :dev), do: []

  def children(true, _, :test) do
    [
      @repo
    ]
  end

  def children(_, _, _), do: []
end
