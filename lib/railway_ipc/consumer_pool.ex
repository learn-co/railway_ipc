defmodule RailwayIpc.ConsumerPool do
  @consumer_max_channels Application.get_env(:railway_ipc, :consumer_max_channels, 10)
  import RailwayIpc.RabbitMQ.RabbitMQAdapter, only: [connection_options: 0]

  def rabbitmq_config do
    [channels: @consumer_max_channels]
    |> Keyword.merge(connection_options())
  end

  def connection_pools do
    consumer_pool = [
      name: {:local, :consumer_pool},
      worker_module: ExRabbitPool.Worker.RabbitConnection,
      size: 1,
      max_overflow: 0
    ]

    [consumer_pool]
  end

  def child_spec(_opts) do
    %{
      id: __MODULE__,
      start:
        {ExRabbitPool.PoolSupervisor, :start_link,
         [
           [
             rabbitmq_config: rabbitmq_config(),
             connection_pools: connection_pools()
           ],
           __MODULE__
         ]},
      type: :supervisor
    }
  end
end
