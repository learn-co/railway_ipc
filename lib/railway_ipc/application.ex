defmodule RailwayIpc.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {RailwayIpc.Connection, [name: RailwayIpc.Connection]}
    ]

    opts = [strategy: :one_for_one, name: RailwayIpc.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
