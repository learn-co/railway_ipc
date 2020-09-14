defmodule RailwayIpc.RPCPool do
  def rabbitmq_config do
    [channels: 10]
  end

  def connection_pools do
    rpc_pool = [
      name: {:local, :rpc_pool},
      worker_module: ExRabbitPool.Worker.RabbitConnection,
      size: 1,
      max_overflow: 0
    ]

    [rpc_pool]
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
