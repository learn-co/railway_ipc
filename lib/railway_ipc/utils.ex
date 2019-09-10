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
end
