Application.load(:railway_ipc)

for app <- Application.spec(:railway_ipc, :applications) do
  Application.ensure_all_started(app)
end

# End to end integration tests are slow and require a running RabbitMQ
# instance so don't run them by default. You can run them using
#
# `MIX_ENV=e2e mix test --only e2e`.
#
# Notice that you must specify the mix environment as `e2e` so that
# we don't enable Mox.
# End to end tests will always be ran in CI.
ExUnit.configure(exclude: [e2e: true])
ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(RailwayIpc.Dev.Repo, :manual)
