defmodule LearnIpc.Events.Admission.ApplicantAdmitted.Data do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          applicant: LearnIpc.Entities.AdmittedApplicant.t() | nil
        }
  defstruct [:applicant]

  field(:applicant, 1, type: LearnIpc.Entities.AdmittedApplicant)
end

defmodule LearnIpc.Events.Admission.ApplicantAdmitted.ContextEntry do
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

defmodule LearnIpc.Events.Admission.ApplicantAdmitted do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          user_uuid: String.t(),
          correlation_id: String.t(),
          uuid: String.t(),
          context: %{String.t() => String.t()},
          data: LearnIpc.Events.Admission.ApplicantAdmitted.Data.t() | nil
        }
  defstruct [:user_uuid, :correlation_id, :uuid, :context, :data]

  field(:user_uuid, 1, type: :string)
  field(:correlation_id, 2, type: :string)
  field(:uuid, 3, type: :string)

  field(:context, 4,
    repeated: true,
    type: LearnIpc.Events.Admission.ApplicantAdmitted.ContextEntry,
    map: true
  )

  field(:data, 5, type: LearnIpc.Events.Admission.ApplicantAdmitted.Data)
end
