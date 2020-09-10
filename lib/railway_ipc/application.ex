defmodule RailwayIpc.Application do
  @moduledoc false

  use Application
  @use_dev_repo Application.get_env(:railway_ipc, :dev_repo)
  @repo Application.get_env(:railway_ipc, :repo, RailwayIpc.Dev.Repo)
  alias RailwayIpc.Loggers.ConsumerEvents
  alias RailwayIpc.Loggers.PublisherEvents
  alias RailwayIpc.Telemetry

  def start(_type, _args) do
    setup_rabbit_log_level()

    attach_consumer_loggers()
    attach_publisher_loggers()
    opts = [strategy: :one_for_one, name: RailwayIpc.Supervisor]
    Supervisor.start_link(pools() ++ maybe_load_repo(@use_dev_repo), opts)
  end

  def maybe_load_repo(true) do
    [@repo]
  end

  def maybe_load_repo(_) do
    []
  end

  def pools do
    [
      RailwayIpc.ConsumerPool,
      RailwayIpc.PublisherPool
    ]
  end

  defp attach_publisher_loggers do
    :ok =
      Telemetry.attach_many(
        "log-publisher-events",
        [
          [:railway_ipc, :rabbit_publish, :start],
          [:railway_ipc, :rabbit_direct_publish, :start],
          [:railway_ipc, :publisher_publish, :start],
          [:railway_ipc, :publisher_direct_publish, :start],
          [:railway_ipc, :publisher_rpc_publish, :start],
          [:railway_ipc, :publisher_rpc_response, :stop]
        ],
        &PublisherEvents.handle_event/4
      )
  end

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

  defp setup_rabbit_log_level() do
    :logger.add_primary_filter(
      :ignore_rabbitmq_progress_reports,
      {&:logger_filters.domain/2, {:stop, :equal, [:progress]}}
    )
  end
end
