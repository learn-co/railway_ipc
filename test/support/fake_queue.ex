defmodule Test.Support.FakeQueue do
  @moduledoc """
  Message bus implemented as an in-memory queue for tests.

  """

  @behaviour RailwayIpc.MessageBus
  @me __MODULE__

  alias RailwayIpc.MessageBus.Publisher

  def init do
    Agent.start_link(fn -> [] end, name: @me)
  end

  @impl RailwayIpc.MessageBus
  def publish(_channel, exchange, encoded, format) do
    if Regex.match?(~r/"publish":false/, encoded) do
      {:error, "failed to publish"}
    else
      msg = %{exchange: exchange, encoded: encoded, format: format}
      Agent.update(@me, fn messages -> [msg | messages] end)
      {:ok, true}
    end
  end

  @impl RailwayIpc.MessageBus
  def setup_publisher do
    {:ok, %Publisher{}}
  end

  @impl RailwayIpc.MessageBus
  def cleanup_publisher(%Publisher{}) do
    Agent.update(@me, fn _ -> [] end)
    :ok
  end

  def message_count do
    Enum.count(messages())
  end

  def has_message?(msg_map) do
    Enum.member?(messages(), msg_map)
  end

  def messages do
    Agent.get(@me, fn messages -> messages end)
  end
end
