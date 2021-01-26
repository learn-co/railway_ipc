defmodule RailwayIpc.Core.PayloadTest do
  use ExUnit.Case
  alias RailwayIpc.Core.Payload

  test "properly encodes type" do
    command = Commands.DoAThing.new(uuid: "123123")
    encoded_type = Payload.encode_type(command)
    assert encoded_type == "Commands::DoAThing"
  end

  test "encodes payloads properly" do
    command = Commands.DoAThing.new(uuid: "123123")
    {:ok, encoded} = Payload.encode(command)
    assert encoded == "{\"encoded_message\":\"GgYxMjMxMjM=\",\"type\":\"Commands::DoAThing\"}"
  end

  test "properly decodes message" do
    command = Commands.DoAThing.new(uuid: "123123")
    {:ok, encoded} = Payload.encode(command)
    {:ok, decoded} = Payload.decode(encoded)

    assert decoded.__struct__ == Commands.DoAThing
    assert decoded.uuid == "123123"
  end

  test "properly decodes message with whitespace" do
    encoded = "{\"encoded_message\":\"GgYxMjMxMjM=\",\"type\":\"Commands::DoAThing\"}\n"
    {:ok, decoded} = Payload.decode(encoded)

    assert decoded.__struct__ == Commands.DoAThing
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
