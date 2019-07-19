defmodule LearnIpcEx.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      {LearnIpcEx.Connection, [name: LearnIpcEx.Connection]}
    ]

    opts = [strategy: :one_for_one, name: LearnIpcEx.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
