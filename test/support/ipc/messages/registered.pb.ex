defmodule LearnIpc.Events.Student.Registered.ContextEntry do
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

defmodule LearnIpc.Events.Student.Registered do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          user_uuid: String.t(),
          correlation_id: String.t(),
          uuid: String.t(),
          context: %{String.t() => String.t()},
          data: LearnIpc.Entities.Student.t() | nil
        }
  defstruct [:user_uuid, :correlation_id, :uuid, :context, :data]

  field(:user_uuid, 1, type: :string)
  field(:correlation_id, 2, type: :string)
  field(:uuid, 3, type: :string)

  field(:context, 4,
    repeated: true,
    type: LearnIpc.Events.Student.Registered.ContextEntry,
    map: true
  )

  field(:data, 5, type: LearnIpc.Entities.Student)
end
