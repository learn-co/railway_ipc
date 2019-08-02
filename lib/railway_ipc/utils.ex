defmodule RailwayIpc.Utils do
  def module_defined?(module) do
    try do
      module.__info__(:module) # forces module to be loaded
      true
    rescue
      UndefinedFunctionError -> false
    end
  end
end
