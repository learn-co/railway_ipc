defmodule RailwayIpc.Telemetry do
  @moduledoc """
  Description of all events
  """

  def span(name, meta, func) when is_function(func, 0) do
    :telemetry.span([:railway_ipc, name], meta, func)
  end

  def start(name, meta, measurements \\ %{}) do
    time = System.monotonic_time()
    measures = Map.put(measurements, :system_time, time)
    :telemetry.execute([:railway_ipc, name, :start], measures, meta)
    time
  end

  def stop(name, start_time, meta, measurements \\ %{}) do
    end_time = System.monotonic_time()
    measurements = Map.merge(measurements, %{duration: end_time - start_time})

    :telemetry.execute(
      [:railway_ipc, name, :stop],
      measurements,
      meta
    )
  end

  def exception(event, start_time, kind, reason, stack, meta \\ %{}, extra_measurements \\ %{}) do
    end_time = System.monotonic_time()
    measurements = Map.merge(extra_measurements, %{duration: end_time - start_time})

    meta =
      meta
      |> Map.put(:kind, kind)
      |> Map.put(:error, reason)
      |> Map.put(:stacktrace, stack)

    :telemetry.execute([:railway_ipc, event, :exception], measurements, meta)
  end

  def event(name, metrics, meta) do
    :telemetry.execute([:railway_ipc, name], metrics, meta)
  end

  def track_application_start(meta, func) when is_function(func, 0) do
    span(:initialization, meta, func)
  end

  def track_opening_connection(func) when is_function(func, 0) do
    span(:connection_process, %{}, func)
  end

  def track_connecting_to_rabbit(func) when is_function(func, 0) do
    span(:rabbit_connection, %{}, func)
  end

  def track_getting_rabbit_channel(func) when is_function(func, 0) do
    span(:get_rabbit_channel, %{}, func)
  end

  def track_rabbit_publish(meta, func) when is_function(func, 0) do
    span(:rabbit_publish, meta, func)
  end

  def track_rabbit_direct_publish(meta, func) when is_function(func, 0) do
    span(:rabbit_direct_publish, meta, func)
  end

  def track_publisher_publish(meta, func) when is_function(func, 0) do
    span(:publisher_publish, meta, func)
  end

  def track_publisher_direct_publish(meta, func) when is_function(func, 0) do
    span(:publisher_direct_publish, meta, func)
  end

  def track_rpc_publish(meta, func) when is_function(func, 0) do
    span(:publisher_rpc_publish, meta, func)
  end

  def track_rpc_response(meta, func) when is_function(func, 0) do
    span(:publisher_rpc_response, meta, func)
  end

  def track_adding_consumer(meta, func) when is_function(func, 0) do
    span(:add_consumer, meta, func)
  end

  def track_consumer_connected(meta) do
    event([:railway_ipc, :consumer_connected], %{}, meta)
  end

  def track_receive_message(meta, func) when is_function(func, 0) do
    span(:consumer_receive_message, meta, func)
  end

  def track_process_message(meta, func) when is_function(func, 0) do
    span(:consumer_process_message, meta, func)
  end

  def track_decode(meta, func) when is_function(func, 0) do
    span(:consumer_decode_message, meta, func)
  end

  def track_persist(meta, func) when is_function(func, 0) do
    span(:consumer_persist_message, meta, func)
  end

  def track_handle_message(meta, func) when is_function(func, 0) do
    span(:consumer_handle_message, meta, func)
  end

  def attach_many(name, events, handler) do
    :telemetry.attach_many(
      name,
      events,
      handler,
      nil
    )
  end
end
