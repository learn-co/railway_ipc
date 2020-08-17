defmodule RailwayIpc.Utils do
  def module_defined?(module) do
    try do
      # forces module to be loaded
      module.__info__(:module)
      true
    rescue
      UndefinedFunctionError -> false
    end
  end

  def protobuf_to_map(protobuf) do
    protobuf
    |> Map.from_struct()
    |> Map.new(fn
      {k, %_{} = struct} -> {k, protobuf_to_map(struct)}
      {_k, _v} = r -> r
    end)
  end
end
