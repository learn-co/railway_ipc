defmodule RailwayIpc.Core.PayloadTest do
  use ExUnit.Case
  alias RailwayIpc.Core.Payload

  test "properly encodes type" do
    command = Commands.DoAThing.new(uuid: "123123")
    encoded_type = Payload.encode_type(command)
    assert encoded_type == "Commands::DoAThing"
  end

  test "properly encodes struct" do
    command = Commands.DoAThing.new(uuid: "123123")
    encoded_message = Payload.encode_message(command)
    assert encoded_message == "GgYxMjMxMjM="
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

    assert reason ==
             "Missing keys: {\"bogus_key\":\"Banana\"}. Expecting type and encoded_message keys"
  end

  test "returns an error if given bad data" do
    {:error, reason} = Payload.decode("")
    assert reason == "Malformed JSON given: "
  end

  test "returns an error if anything other than a string given" do
    {:error, reason} = Payload.decode(123_123)
    assert reason == "Malformed JSON given: 123123. Must be a string"
  end

  test "returns an error if the module is unknown after decoding" do
    json =
      %{type: "BogusModule", encoded_message: ""}
      |> Jason.encode!()

    {:error, reason} = Payload.decode(json)
    assert reason == "Unknown message type BogusModule"
  end
end
