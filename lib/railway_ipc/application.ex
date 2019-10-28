defmodule RailwayIpc.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    opts = [strategy: :one_for_one, name: RailwayIpc.Supervisor]
    IO.puts "MIX ENV: #{Mix.env()}"
    Supervisor.start_link(children(Mix.env()), opts)
  end

  # def children(:test) do
  #   [
  #     RailwayIpc.Dev.Repo
  #   ]
  # end
  #
  # def children(:dev) do
  #   [
  #     RailwayIpc.Dev.Repo
  #   ]
  # end

  def children(_) do
    []
  end
end
