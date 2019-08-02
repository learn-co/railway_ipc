defmodule Mix.Tasks.GenerateTestProtobufs do
  use Mix.Task
  @shortdoc "Generates test protobufs"
  def run(_arg) do
    :os.cmd(
      'protoc --proto_path=test/support/ipc/protobuf --elixir_out=test/support/ipc/messages test/support/ipc/protobuf/*.proto'
    )

    IO.puts("Generated successfully")
  end
end
