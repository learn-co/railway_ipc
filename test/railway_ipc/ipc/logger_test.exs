defmodule RailwayIpc.Ipc.LoggerTest do
  use ExUnit.Case
  import ExUnit.CaptureLog
  alias RailwayIpc.Ipc.Logger
  @logger_metadata Application.get_env(:railway_ipc, :logger_metadata)

  def clean_log(log) do
    log
    |> String.replace("\e[22m", "")
    |> String.replace("\e[0m", "")
    |> String.trim()
  end

  def decode_log(log) do
    log |> Jason.decode!()
  end

  def assert_has_keys(decoded_log, keys) do
    decoded_log
    |> Map.keys()
    |> Enum.each(&assert &1 in keys, "Expected #{inspect(&1)} in #{inspect(keys)}")

    decoded_log
  end

  def assert_has_value(decoded_log, keys, value) when is_list(keys) do
    assert keys
           |> Enum.reduce(decoded_log, fn key, acc ->
             Map.get(acc, key)
           end) == value

    decoded_log
  end

  def assert_has_value(decoded_log, key, value) do
    assert_has_value(decoded_log, [key], value)
  end

  def capture_json_log(fun) when is_function(fun, 0) do
    [metadata: @logger_metadata]
    |> capture_log(fun)
    |> clean_log
    |> decode_log
  end

  describe "info/2" do
    test "accepts string as first argument" do
      message_uuid = Ecto.UUID.generate()
      correlation_id = Ecto.UUID.generate()
      user_uuid = Ecto.UUID.generate()
      context = %{"context" => "data"}

      message =
        Events.AThingWasDone.new(
          uuid: message_uuid,
          correlation_id: correlation_id,
          user_uuid: user_uuid,
          context: context
        )

      Logger.metadata(feature: "railway_ipc_testing", queue: "my_queue", exchange: "my_exchange")
      Logger.metadata(%{message: message, type: "Events.AThingWasDone"})

      logged =
        capture_log([metadata: :all], fn ->
          Logger.info("My Message")
        end)
        |> clean_log

      assert logged =~ "My Message"
      assert logged =~ "feature=railway_ipc_testing"
      assert logged =~ "queue=my_queue"
      assert logged =~ "exchange=my_exchange"
      assert logged =~ "correlation_id=#{correlation_id}"
      assert logged =~ "message_type=Events.AThingWasDone"

      assert logged =~
               "message={\"context\":{\"context\":\"data\"},\"correlation_id\":\"#{correlation_id}\",\"user_uuid\":\"#{
                 user_uuid
               }\",\"uuid\":\"#{message_uuid}\"} "
    end
  end
end
