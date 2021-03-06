defmodule RailwayIpc.Application do
  @moduledoc false

  use Application
  @use_dev_repo Application.get_env(:railway_ipc, :dev_repo)
  @repo Application.get_env(:railway_ipc, :repo, RailwayIpc.Dev.Repo)
  @start_supervisor Application.get_env(:railway_ipc, :start_supervisor)
  @mix_env Application.get_env(:railway_ipc, :mix_env, :prod)
  alias RailwayIpc.Loggers.ConsumerEvents
  alias RailwayIpc.Publisher.Logger, as: PublisherLog
  alias RailwayIpc.Telemetry

  def start(_type, _args) do
    setup_rabbit_log_level()

    attach_consumer_loggers()
    :ok = PublisherLog.attach()
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
      @repo,
      {RailwayIpc.Publisher, name: RailwayIpc.Publisher}
    ]
  end

  def children(true, true, :e2e) do
    [
      @repo,
      {RailwayIpc.Connection.Supervisor, []}
    ]
  end

  def children(_, _, _), do: []

  defp attach_consumer_loggers do
    :ok =
      Telemetry.attach_many(
        "log-consumer-events",
        [
          [:railway_ipc, :consumer_connected],
          [:railway_ipc, :add_consumer, :start],
          [:railway_ipc, :consumer_receive_message, :start],
          [:railway_ipc, :consumer_process_message, :start],
          [:railway_ipc, :consumer_process_message, :stop],
          [:railway_ipc, :consumer_decode_message, :stop],
          [:railway_ipc, :consumer_handle_message, :start]
        ],
        &ConsumerEvents.handle_event/4
      )
  end

  defp setup_rabbit_log_level do
    :logger.add_primary_filter(
      :ignore_rabbitmq_progress_reports,
      {&:logger_filters.domain/2, {:stop, :equal, [:progress]}}
    )
  end
end
