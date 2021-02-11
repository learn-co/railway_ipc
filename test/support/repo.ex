defmodule RailwayIpc.Dev.Repo do
  @moduledoc false
  use Ecto.Repo,
    otp_app: :railway_ipc,
    adapter: Ecto.Adapters.Postgres
end
