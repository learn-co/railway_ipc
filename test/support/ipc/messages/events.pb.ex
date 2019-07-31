defmodule Events.AThingWasDone do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          user_uuid: String.t(),
          correlation_id: String.t(),
          uuid: String.t(),
          context: %{String.t() => String.t()}
        }
  defstruct [:user_uuid, :correlation_id, :uuid, :context]

  field :user_uuid, 1, type: :string
  field :correlation_id, 2, type: :string
  field :uuid, 3, type: :string
  field :context, 4, repeated: true, type: Events.AThingWasDone.ContextEntry, map: true
end

defmodule Events.AThingWasDone.ContextEntry do
  @moduledoc false
  use Protobuf, map: true, syntax: :proto3

  @type t :: %__MODULE__{
          key: String.t(),
          value: String.t()
        }
  defstruct [:key, :value]

  field :key, 1, type: :string
  field :value, 2, type: :string
end

defmodule Events.FailedToDoAThing do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          user_uuid: String.t(),
          correlation_id: String.t(),
          uuid: String.t(),
          context: %{String.t() => String.t()}
        }
  defstruct [:user_uuid, :correlation_id, :uuid, :context]

  field :user_uuid, 1, type: :string
  field :correlation_id, 2, type: :string
  field :uuid, 3, type: :string
  field :context, 4, repeated: true, type: Events.FailedToDoAThing.ContextEntry, map: true
end

defmodule Events.FailedToDoAThing.ContextEntry do
  @moduledoc false
  use Protobuf, map: true, syntax: :proto3

  @type t :: %__MODULE__{
          key: String.t(),
          value: String.t()
        }
  defstruct [:key, :value]

  field :key, 1, type: :string
  field :value, 2, type: :string
end
