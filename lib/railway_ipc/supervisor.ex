defmodule RailwayIpc.Connection.Supervisor do
  use Supervisor
  require Logger

  def start_link(children) do
    Logger.warn("""
    DEPRECATION WARNING: RailwayIpc.Connection.Supervisor is going away.
    Going forward, start your consumers directly, or use a RailwayIpc.ConsumerGroup to
    support grouped consumer halting.
    """)

    Supervisor.start_link(__MODULE__, children, name: __MODULE__)
  end

  def init(children) do
    Supervisor.init(children, strategy: :one_for_one)
  end
end
