defmodule RailwayIpc.MessageBus do
  @moduledoc """
  Defines message bus behaviour.

  """

  @doc """
  Open a new message bus connection.

  """
  @callback connect(uri :: binary) :: {:ok, term}

  @doc """
  Close the message bus connection.

  """
  @callback disconnect(connection :: term) :: :ok
end
