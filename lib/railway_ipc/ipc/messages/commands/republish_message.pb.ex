defmodule RailwayIpc.Commands.RepublishMessage do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          user_uuid: String.t(),
          correlation_id: String.t(),
          uuid: String.t(),
          context: %{
            String.t() => String.t() | nil,
            data: RailwayIpc.Commands.RepublishMessage.Data.t() | nil
          }
        }
  defstruct [:user_uuid, :correlation_id, :uuid, :context, :data]

  field(:user_uuid, 1, type: :string)
  field(:correlation_id, 2, type: :string)
  field(:uuid, 3, type: :string)

  field(:context, 4,
    repeated: true,
    type: RailwayIpc.Commands.RepublishMessage.ContextEntry,
    map: true
  )

  field(:data, 5, type: RailwayIpc.Commands.RepublishMessage.Data)
end

defmodule RailwayIpc.Commands.RepublishMessage.Data do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          published_message_uuid: String.t()
        }
  defstruct [:published_message_uuid]

  field(:published_message_uuid, 1, type: :string)
end

defmodule RailwayIpc.Commands.RepublishMessage.ContextEntry do
  @moduledoc false
  use Protobuf, map: true, syntax: :proto3

  @type t :: %__MODULE__{
          key: String.t(),
          value: String.t()
        }
  defstruct [:key, :value]

  field(:key, 1, type: :string)
  field(:value, 2, type: :string)
end
