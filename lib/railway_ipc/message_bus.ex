defmodule RailwayIpc.MessageBus do
  @moduledoc """
  Defines message bus behaviour.

  """

  defmodule Publisher do
    @moduledoc """
    Configuration for all publishers.

    """
    defstruct [:channel, :connection]
  end

  @doc """
  Publish a message.

  """
  @callback publish(
              channel :: term,
              exchange :: term,
              payload :: term,
              format :: String.t()
            ) :: {:ok, true} | {:error, term}

  @doc """
  Setup infrastructure for a publisher. Returns a
  `RailwayIpc.MessageBus.Publisher` struct.

  """
  @callback setup_publisher() :: {:ok, %__MODULE__.Publisher{}} | {:error, term}

  @doc """
  Cleanup and close/disconnect publisher infrastructure.

  """
  @callback cleanup_publisher(publisher :: %__MODULE__.Publisher{}) :: :ok
end
