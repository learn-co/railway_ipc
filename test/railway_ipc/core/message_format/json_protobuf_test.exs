defmodule RailwayIpc.Core.MessageFormat.JsonProtobufTest do
  use ExUnit.Case, async: true

  alias LearnIpc.Entities.AdmittedApplicant
  alias LearnIpc.Entities.Student
  alias LearnIpc.Events.Admission.ApplicantAdmitted
  alias LearnIpc.Events.Compliance.DocumentAssignedToStudent
  alias LearnIpc.Events.Compliance.DocumentAssignedToStudent.Data
  alias LearnIpc.Events.Student.Registered
  alias RailwayIpc.Core.MessageFormat.JsonProtobuf
  alias RailwayIpc.DefaultMessage

  describe "#encode" do
    test "encode a protobuf without data" do
      msg = Events.AThingWasDone.new(uuid: "abc123")

      expected = {
        :ok,
        ~S({"encoded_message":{"context":{},"correlation_id":"",) <>
          ~S("data":null,"user_uuid":"","uuid":"abc123"},) <>
          ~S("type":"Events::AThingWasDone"}),
        "Events::AThingWasDone"
      }

      assert expected == JsonProtobuf.encode(msg)
    end

    test "encode a protobuf with data" do
      msg =
        DocumentAssignedToStudent.new(
          uuid: "abc123",
          context: %{"some" => "value"},
          data: Data.new(student_uuid: "def456")
        )

      expected = {
        :ok,
        ~S({"encoded_message":{"context":{"some":"value"},) <>
          ~S("correlation_id":"","data":{"document_uuid":"",) <>
          ~S("docusign_reference_id":"","kind":"","student_uuid":"def456"},) <>
          ~S("occurred_at":"","user_uuid":"","uuid":"abc123"},) <>
          ~S("type":"LearnIpc::Events::Compliance::DocumentAssignedToStudent"}),
        "LearnIpc::Events::Compliance::DocumentAssignedToStudent"
      }

      assert expected == JsonProtobuf.encode(msg)
    end

    test "encode arbitrarily nested protobufs" do
      msg =
        ApplicantAdmitted.new(
          user_uuid: "abc123",
          correlation_id: "abc123",
          uuid: "abc123",
          context: %{},
          data:
            ApplicantAdmitted.Data.new(
              applicant:
                AdmittedApplicant.new(
                  uuid: "abc123",
                  external_id: "abc123",
                  salesforce_opportunity_id: "abc123"
                )
            )
        )

      expected = {
        :ok,
        ~S({"encoded_message":{"context":{},"correlation_id":"abc123",) <>
          ~S("data":{"applicant":{"external_id":"abc123",) <>
          ~S("salesforce_opportunity_id":"abc123","uuid":"abc123"}},) <>
          ~S("user_uuid":"abc123","uuid":"abc123"},"type":) <>
          ~S("LearnIpc::Events::Admission::ApplicantAdmitted"}),
        "LearnIpc::Events::Admission::ApplicantAdmitted"
      }

      assert expected == JsonProtobuf.encode(msg)
    end

    test "only valid protobufs can be encoded" do
      {:error, error} = JsonProtobuf.encode("foo")
      assert "Argument Error: Valid Protobuf required" == error
    end

    test "bare structs cannot be encoded" do
      {:error, error} = JsonProtobuf.encode(%{foo: 1})
      assert "Argument Error: Valid Protobuf required" == error
    end
  end

  describe "#decode" do
    test "decode a message without data to a protobuf" do
      msg = Events.AThingWasDone.new(uuid: "abc123", context: %{"some" => "value"})
      {:ok, encoded, _type} = JsonProtobuf.encode(msg)

      expected = {
        :ok,
        %Events.AThingWasDone{
          context: %{"some" => "value"},
          correlation_id: "",
          user_uuid: "",
          uuid: "abc123"
        },
        "Events::AThingWasDone"
      }

      assert expected == JsonProtobuf.decode(encoded)
    end

    test "decode a message with data to a protobuf" do
      msg =
        DocumentAssignedToStudent.new(
          uuid: "abc123",
          context: %{"some" => "value"},
          data: Data.new(student_uuid: "def456")
        )

      {:ok, encoded, _type} = JsonProtobuf.encode(msg)

      expected = {
        :ok,
        %LearnIpc.Events.Compliance.DocumentAssignedToStudent{
          context: %{"some" => "value"},
          correlation_id: "",
          user_uuid: "",
          occurred_at: "",
          uuid: "abc123",
          data: %LearnIpc.Events.Compliance.DocumentAssignedToStudent.Data{
            document_uuid: "",
            docusign_reference_id: "",
            kind: "",
            student_uuid: "def456"
          }
        },
        "LearnIpc::Events::Compliance::DocumentAssignedToStudent"
      }

      assert expected == JsonProtobuf.decode(encoded)
    end

    test "decode a message with an entity to a protobuf" do
      msg =
        Registered.new(
          uuid: "abc123",
          context: %{"some" => "value"},
          data: Student.new(learn_uuid: "def456")
        )

      {:ok, encoded, _type} = JsonProtobuf.encode(msg)

      expected = {
        :ok,
        %LearnIpc.Events.Student.Registered{
          context: %{"some" => "value"},
          correlation_id: "",
          user_uuid: "",
          uuid: "abc123",
          data: %LearnIpc.Entities.Student{
            email: "",
            external_id: "",
            first_name: "",
            last_name: "",
            learn_uuid: "def456",
            phone_number: "",
            username: ""
          }
        },
        "LearnIpc::Events::Student::Registered"
      }

      assert expected == JsonProtobuf.decode(encoded)
    end

    test "decode message with nested protobufs" do
      msg =
        ApplicantAdmitted.new(
          user_uuid: "abc123",
          correlation_id: "abc123",
          uuid: "abc123",
          context: %{"some" => "value"},
          data:
            ApplicantAdmitted.Data.new(
              applicant:
                AdmittedApplicant.new(
                  uuid: "abc123",
                  external_id: "abc123",
                  salesforce_opportunity_id: "abc123"
                )
            )
        )

      {:ok, encoded, _type} = JsonProtobuf.encode(msg)

      expected = {
        :ok,
        %LearnIpc.Events.Admission.ApplicantAdmitted{
          context: %{"some" => "value"},
          correlation_id: "abc123",
          user_uuid: "abc123",
          uuid: "abc123",
          data: %LearnIpc.Events.Admission.ApplicantAdmitted.Data{
            applicant: %LearnIpc.Entities.AdmittedApplicant{
              external_id: "abc123",
              salesforce_opportunity_id: "abc123",
              uuid: "abc123"
            }
          }
        },
        "LearnIpc::Events::Admission::ApplicantAdmitted"
      }

      assert expected == JsonProtobuf.decode(encoded)
    end

    test "message must be a string" do
      {:error, error} = JsonProtobuf.decode(:foo)
      assert "Malformed JSON given. Must be a string. (:foo)" == error
    end

    test "message must be valid JSON" do
      {:error, error} = JsonProtobuf.decode("not_json")
      assert "Message is invalid JSON (not_json)" == error
    end

    test "message must include a type attribute" do
      {:error, error} = JsonProtobuf.decode("{}")
      assert "Message is missing the `type` attribute" == error
    end

    test "message protobuf type must be string" do
      message = %{type: 1} |> Jason.encode!()
      {:error, error} = JsonProtobuf.decode(message)
      assert "Message `type` attribute must be a string" == error
    end

    test "use default message protobuf if module is not defined" do
      message = %{type: "NotAModule", encoded_message: %{}} |> Jason.encode!()
      {:unknown_message_type, proto, type} = JsonProtobuf.decode(message)
      assert DefaultMessage == proto.__struct__
      assert "NotAModule" == type
    end

    test "enclosed encoded message must be a decodable protobuf" do
      message =
        %{type: "Events.AThingWasDone", encoded_message: "invalid"}
        |> Jason.encode!()

      {:error, error} = JsonProtobuf.decode(message)
      assert "Cannot decode protobuf" == error
    end
  end
end
