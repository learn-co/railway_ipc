defmodule RailwayIpc.PublisherPool do
  @publisher_max_channels Application.get_env(:railway_ipc, :publisher_max_channels, 2)
  def rabbitmq_config do
    [channels: @publisher_max_channels]
  end

  def connection_pools do
    publisher_pool = [
      name: {:local, :publisher_pool},
      worker_module: ExRabbitPool.Worker.RabbitConnection,
      size: 1,
      max_overflow: 0
    ]

    [publisher_pool]
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
