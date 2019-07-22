Application.load(:learn_ipc_ex)

for app <- Application.spec(:learn_ipc_ex, :applications) do
  Application.ensure_all_started(app)
end

ExUnit.start()
