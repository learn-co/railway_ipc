defmodule Mix.Tasks.GenerateTestProtobufs do
  @moduledoc false
  use Mix.Task

  import Mix.Support.SystemCommandHelper

  @shortdoc "Generates test protobufs"
  def run(_arg) do
    run_system_command("""
    protoc --proto_path=test/support/ipc/protobuf \
            --elixir_out=test/support/ipc/messages \
            test/support/ipc/protobuf/*.proto
    """)

    IO.puts("Generated successfully")
  end
end
