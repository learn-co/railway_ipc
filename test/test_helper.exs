Application.load(:railway_ipc)

for app <- Application.spec(:railway_ipc, :applications) do
  Application.ensure_all_started(app)
end

ExUnit.start()
