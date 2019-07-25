defmodule RailwayIpc.Utils do
  def module_defined?(module), do: function_exported?(module, :__info__, 1)
end
