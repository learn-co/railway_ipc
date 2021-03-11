defmodule RailwayIpc.PublisherTest do
  use RailwayIpc.DataCase, async: true

  import Test.Support.Helpers

  alias RailwayIpc.Publisher
  alias RailwayIpc.Publisher.Logger, as: PublishLog
  alias Test.Support.FakeQueue

  @uuid "49b38c1b-8cc3-4b1c-a58a-5a3dd206cd92"

  setup :attach_telemetry_handlers

  setup do
    {:ok, _} = FakeQueue.init()
    :ok
  end

  describe "successful publish" do
    setup do
      %{proto: Events.AThingWasDone.new(uuid: @uuid)}
    end

    test "telemetry start is emitted", %{proto: proto} do
      {:ok, _} = Publisher.publish("railwayipc:test", proto, "json_protobuf")

      assert_receive {
        :telemetry_event,
        [:railway_ipc, :publisher, :publish, :start],
        %{system_time: _},
        %{module: _, exchange: _, protobuf: _}
      }
    end

    test "message is stored", %{proto: proto} do
      assert_difference row_count("railway_ipc_published_messages"), by: 1 do
        {:ok, _} = Publisher.publish("railwayipc:test", proto, "json_protobuf")
      end
    end

    test "message is published to message bus", %{proto: proto} do
      assert_difference FakeQueue.message_count(), by: 1 do
        {:ok, _} = Publisher.publish("railwayipc:test", proto, "json_protobuf")
      end

      expected_msg = %{
        exchange: "railwayipc:test",
        format: "json_protobuf",
        encoded:
          ~s({"encoded_message":{"context":{},"correlation_id":"",) <>
            ~s("data":null,"user_uuid":"",) <>
            ~s("uuid":"#{@uuid}"},) <>
            ~s("type":"Events::AThingWasDone"})
      }

      assert FakeQueue.has_message?(expected_msg),
             "#{inspect(expected_msg, pretty: true)} not found in #{
               inspect(FakeQueue.messages(), pretty: true)
             }"
    end

    test "telemetry finish is emitted", %{proto: proto} do
      {:ok, _} = Publisher.publish("railwayipc:test", proto, "json_protobuf")

      assert_receive {
        :telemetry_event,
        [:railway_ipc, :publisher, :publish, :stop],
        %{system_time: _, duration: _},
        %{module: _, exchange: _, protobuf: _, message: _}
      }
    end
  end

  describe "failed to encode message" do
    setup do
      %{proto: "not a protobuf"}
    end

    test "returns an error tuple with an error message", %{proto: proto} do
      expected = {:error, "Argument Error: Valid Protobuf required"}
      assert expected == Publisher.publish("railwayipc:test", proto, "json_protobuf")
    end

    test "message is not stored", %{proto: proto} do
      assert_difference row_count("railway_ipc_published_messages"), by: 0 do
        {:error, _} = Publisher.publish("railwayipc:test", proto, "json_protobuf")
      end
    end

    test "message is not published", %{proto: proto} do
      assert_difference FakeQueue.message_count(), by: 0 do
        {:error, _} = Publisher.publish("railwayipc:test", proto, "json_protobuf")
      end
    end

    test "telemetry error is emitted", %{proto: proto} do
      {:error, _} = Publisher.publish("railwayipc:test", proto, "json_protobuf")

      assert_receive {
        :telemetry_event,
        [:railway_ipc, :publisher, :publish, :error],
        %{system_time: _},
        %{
          module: _,
          exchange: _,
          protobuf: _,
          reason: "Argument Error: Valid Protobuf required"
        }
      }
    end
  end

  describe "failed to store message" do
    setup do
      %{proto: Events.AThingWasDone.new()}
    end

    test "returns an error tuple with an error message", %{proto: proto} do
      expected = {:error, "Uuid can't be blank"}
      assert expected == Publisher.publish("railwayipc:test", proto, "json_protobuf")
    end

    test "message is not stored", %{proto: proto} do
      assert_difference row_count("railway_ipc_published_messages"), by: 0 do
        {:error, _} = Publisher.publish("railwayipc:test", proto, "json_protobuf")
      end
    end

    test "message is not published", %{proto: proto} do
      assert_difference FakeQueue.message_count(), by: 0 do
        {:error, _} = Publisher.publish("railwayipc:test", proto, "json_protobuf")
      end
    end

    test "telemetry error is emitted", %{proto: proto} do
      {:error, _} = Publisher.publish("railwayipc:test", proto, "json_protobuf")

      assert_receive {
        :telemetry_event,
        [:railway_ipc, :publisher, :publish, :error],
        %{system_time: _},
        %{
          module: _,
          exchange: _,
          protobuf: _,
          reason: "Uuid can't be blank"
        }
      }
    end
  end

  describe "failed to publish message" do
    setup do
      %{proto: Events.AThingWasDone.new(uuid: @uuid, context: %{publish: false})}
    end

    test "returns an error tuple with an error message", %{proto: proto} do
      {:error, msg} = Publisher.publish("railwayipc:test", proto, "json_protobuf")
      assert "failed to publish" == msg
    end

    @tag :skip
    test "message is not stored? or stored? if stored status should not be 'sent'"

    test "message is not published", %{proto: proto} do
      assert_difference FakeQueue.message_count(), by: 0 do
        {:error, _} = Publisher.publish("railwayipc:test", proto, "json_protobuf")
      end
    end

    test "telemetry error is emitted", %{proto: proto} do
      {:error, _} = Publisher.publish("railwayipc:test", proto, "json_protobuf")

      assert_receive {
        :telemetry_event,
        [:railway_ipc, :publisher, :publish, :error],
        %{system_time: _},
        %{
          module: _,
          exchange: _,
          protobuf: _,
          reason: "failed to publish"
        }
      }
    end
  end

  defp attach_telemetry_handlers(%{test: test}) do
    self = self()

    :ok =
      :telemetry.attach_many(
        "#{test}",
        PublishLog.events(),
        fn name, measurements, metadata, _config ->
          send(self, {:telemetry_event, name, measurements, metadata})
        end,
        nil
      )
  end
end
