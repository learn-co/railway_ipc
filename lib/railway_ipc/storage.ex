defmodule RailwayIpc.Storage do
  @moduledoc """
  Behaviour specification for message persistence.

  Any message persistence adapters must conform to this behaviour. Railway
  ships with a Ecto adapter, but you may define your own. For example, you
  may define your own no-op implementation if you do not wish to persist
  messages. You can then override the Railway configuration to use your
  custom adapter.

  ```
  config :railway_ipc,
    storage: MyCustomAdapter
  ```

  Note that this behaviour is incomplete, it only handles outgoing (published)
  messages. This is part of an ongoing refactoring to clean up the internal
  API of Railway. Support for incoming (consumed) messages will be added at a
  later date.

  """

  defmodule OutgoingMessage do
    @moduledoc """
    Represents an outgoing message and its metadata.

    """
    defstruct [:protobuf, :encoded, :exchange, :type]
  end

  @doc """
  Inserts an outgoing message into the message store.

  """
  @callback insert(message :: %__MODULE__.OutgoingMessage{}) ::
              {:ok, term} | {:error, term}
end
