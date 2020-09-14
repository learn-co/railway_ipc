defmodule RailwayIpc.Application do
  @moduledoc false

  use Application
  @use_dev_repo Application.get_env(:railway_ipc, :dev_repo)
  @repo Application.get_env(:railway_ipc, :repo, RailwayIpc.Dev.Repo)
  @mix_env Application.get_env(:railway_ipc, :mix_env, :prod)
  alias RailwayIpc.Loggers.ConsumerEvents
  alias RailwayIpc.Loggers.PublisherEvents
  alias RailwayIpc.Telemetry

  def start(_type, _args) do
    Telemetry.track_application_start(
      %{},
      fn ->
        setup_rabbit_log_level()

        attach_consumer_loggers()
        attach_publisher_loggers()
        opts = [strategy: :one_for_one, name: RailwayIpc.Supervisor]

        result =
          Supervisor.start_link(
            pools() ++
              start_republished_messages_consumer(@mix_env) ++ maybe_load_repo(@use_dev_repo),
            opts
          )

        {result, %{}}
      end
    )
  end

  def maybe_load_repo(true) do
    [@repo]
  end

  def maybe_load_repo(_) do
    []
  end

  def start_republished_messages_consumer(:test) do
    []
  end

  def start_republished_messages_consumer(_) do
    [RailwayIpc.Ipc.RepublishedMessagesConsumer]
  end

  def pools do
    [
      RailwayIpc.ConsumerPool,
      RailwayIpc.RPCPool,
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
