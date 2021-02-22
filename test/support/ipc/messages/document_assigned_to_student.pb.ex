defmodule LearnIpc.Events.Compliance.DocumentAssignedToStudent.Data do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          student_uuid: String.t(),
          kind: String.t(),
          document_uuid: String.t(),
          docusign_reference_id: String.t()
        }
  defstruct [:student_uuid, :kind, :document_uuid, :docusign_reference_id]

  field(:student_uuid, 1, type: :string)
  field(:kind, 2, type: :string)
  field(:document_uuid, 3, type: :string)
  field(:docusign_reference_id, 4, type: :string)
end

defmodule LearnIpc.Events.Compliance.DocumentAssignedToStudent.ContextEntry do
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

defmodule LearnIpc.Events.Compliance.DocumentAssignedToStudent do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          user_uuid: String.t(),
          correlation_id: String.t(),
          uuid: String.t(),
          context: %{String.t() => String.t()},
          data: LearnIpc.Events.Compliance.DocumentAssignedToStudent.Data.t() | nil,
          occurred_at: String.t()
        }
  defstruct [:user_uuid, :correlation_id, :uuid, :context, :data, :occurred_at]

  field(:user_uuid, 1, type: :string)
  field(:correlation_id, 2, type: :string)
  field(:uuid, 3, type: :string)

  field(:context, 4,
    repeated: true,
    type: LearnIpc.Events.Compliance.DocumentAssignedToStudent.ContextEntry,
    map: true
  )

  field(:data, 5, type: LearnIpc.Events.Compliance.DocumentAssignedToStudent.Data)
  field(:occurred_at, 6, type: :string)
end
