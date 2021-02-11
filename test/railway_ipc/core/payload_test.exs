defmodule RailwayIpc.Core.PayloadTest do
  use ExUnit.Case
  alias RailwayIpc.Core.Payload

  test "encodes payloads properly" do
    event = Events.AThingWasDone.new(uuid: "123123")
    {:ok, encoded, type} = Payload.encode(event)
    assert encoded == "{\"encoded_message\":\"GgYxMjMxMjM=\",\"type\":\"Events::AThingWasDone\"}"
    assert type == "Events::AThingWasDone"
  end

  test "properly decodes message" do
    event = Events.AThingWasDone.new(uuid: "123123")
    {:ok, encoded, _type} = Payload.encode(event)
    {:ok, decoded, type} = Payload.decode(encoded)

    assert type == "Events::AThingWasDone"
    assert decoded.__struct__ == Events.AThingWasDone
    assert decoded.uuid == "123123"
  end

  test "properly decodes message with whitespace" do
    encoded = "{\"encoded_message\":\"GgYxMjMxMjM=\",\"type\":\"Events::AThingWasDone\"}\n"
    {:ok, decoded, _type} = Payload.decode(encoded)

    assert decoded.__struct__ == Events.AThingWasDone
  end

  test "returns an error if given bad JSON" do
    json =
      %{bogus_key: "Banana"}
      |> Jason.encode!()

    {:error, reason} = Payload.decode(json)

    assert reason == "Message is missing the `type` attribute"
  end

  test "returns an error if given bad data" do
    {:error, reason} = Payload.decode("not_json")
    assert reason == "Message is invalid JSON (not_json)"
  end

  test "returns an error if anything other than a string given" do
    {:error, reason} = Payload.decode(123_123)
    assert reason == "Malformed JSON given. Must be a string. (123123)"
  end

  test "returns :unknown_message_type tuple if the module is unknown after decoding" do
    json =
      %{type: "BogusModule", encoded_message: ""}
      |> Jason.encode!()

    {:unknown_message_type, _message, "BogusModule"} = Payload.decode(json)
  end
end
