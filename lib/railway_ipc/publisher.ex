defmodule RailwayIpc.Publisher do
  @moduledoc """
  Publishes Protobuf messages to the configured message bus.

  You will define one publisher for each message bus exchange to which you
  want to publish. Define a module that "uses" `RailwayIpc.Publisher`,
  specifying the name of the exchange. Add a function that calls `publish`
  to publish your protobuf message. For example:

  ```
  defmodule MyApp.MyPublisher do
    use RailwayIpc.Publisher, exchange: "my:exchange"

    def publish_something(params) do
      proto = # initialize a Protobuf using params
      case publish(proto, "json_protobuf") do
        {:ok, _info} -> :ok
        {:error, error} -> IO.puts(error)
      end
    end
  end
  ```

  #### A Note on Exchange Types
  The RailwayIpc package enforces an exchange type of "fanout" for ALL
  consumers and publishers. At this time, you cannot override this option.

  """

  alias RailwayIpc.Core.Payload
  alias RailwayIpc.Publisher.Server
  alias RailwayIpc.Publisher.Telemetry
  alias RailwayIpc.Storage.OutgoingMessage

  defmacro __using__(opts) do
    quote do
      @doc """
      Publish a message to the configured exchange.

      Optionally, provide a `format`. Supported formats are
      `"binary_protobuf"` and `"json_protobuf"`. If `format` is not provided,
      `"binary_protobuf"` is used.

      `publish` will return a `{:ok, info}` tuple if successful. `info` is a
      map containing information about the published message (i.e. exchange,
      encoded message, format, etc.). The shape of the `info` map may change
      in future versions. If the message fails to publish, a `{:error, msg}`
      tuple will be returned. `msg` will be a string containing the error
      message.

      """
      def publish(message, format \\ "binary_protobuf") do
        exchange = unquote(Keyword.get(opts, :exchange))
        RailwayIpc.Publisher.publish(exchange, message, format)
      end
    end
  end

  @doc """
  Starts the publisher GenServer.

  """
  def start_link(options \\ []) do
    config = %Server{adapter: Application.fetch_env!(:railway_ipc, :message_bus)}
    GenServer.start_link(Server, config, options)
  end

  @doc false
  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end

  @doc """
  Publishes a protobuf message to an exchange in the given format.

  """
  def publish(exchange, proto, format) do
    %{exchange: exchange, protobuf: proto, format: format}
    |> emit_telemetry_start()
    |> encode_message()
    |> store_message()
    |> publish_to_message_bus()
    |> emit_telemetry_finish()
  end

  defp emit_telemetry_start(info) do
    %{exchange: exchange, protobuf: proto} = info
    start_time = Telemetry.emit_publish_start(__MODULE__, exchange, proto)
    Map.put(info, :start_time, start_time)
  end

  defp encode_message(info) do
    %{protobuf: proto, format: format} = info

    case Payload.encode(proto, format) do
      {:ok, encoded, type} ->
        {:ok, Map.merge(info, %{encoded: encoded, type: type})}

      {:error, error} ->
        {:error, Map.put(info, :error, error)}
    end
  end

  defp store_message({:ok, info}) do
    %{protobuf: proto, encoded: encoded, exchange: exchange, type: type} = info

    msg = %OutgoingMessage{
      protobuf: proto,
      encoded: encoded,
      exchange: exchange,
      type: type
    }

    case message_store().insert(msg) do
      {:ok, _} -> {:ok, info}
      {:error, error} -> {:error, Map.put(info, :error, error)}
    end
  end

  defp store_message({:error, error}), do: {:error, error}

  defp publish_to_message_bus({:ok, info}) do
    %{exchange: exchange, encoded: encoded, format: format} = info

    case GenServer.call(__MODULE__, {:publish, exchange, encoded, format}) do
      :ok -> {:ok, info}
      {:error, reason} -> {:error, Map.put(info, :error, reason)}
    end
  end

  defp publish_to_message_bus({:error, error}), do: {:error, error}

  defp emit_telemetry_finish({status, info}) do
    %{start_time: start, exchange: exchange, protobuf: proto} = info

    case status do
      :ok ->
        Telemetry.emit_publish_stop(__MODULE__, start, exchange, proto, info.encoded)
        {:ok, info}

      :error ->
        Telemetry.emit_publish_error(__MODULE__, start, exchange, proto, info.error)
        {:error, info.error}
    end
  end

  defp message_store do
    Application.fetch_env!(:railway_ipc, :storage)
  end
end
