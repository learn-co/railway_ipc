defmodule RailwayIpc.Persistence do
  @moduledoc false
  @behaviour RailwayIpc.PersistenceBehaviour
  @repo Application.get_env(:railway_ipc, :repo, RailwayIpc.Dev.Repo)
  alias RailwayIpc.Persistence.{ConsumedMessage, ConsumedMessageAdapter}

  alias RailwayIpc.MessageConsumption
  import Ecto.Query

  def insert_consumed_message(%MessageConsumption{
        exchange: exchange,
        queue: queue,
        inbound_message: inbound_message
      }) do
    {:ok, persistence_attrs} =
      inbound_message
      |> ConsumedMessageAdapter.to_persistence(exchange, queue)

    %ConsumedMessage{}
    |> ConsumedMessage.changeset(persistence_attrs)
    |> @repo.insert()
  end

  def update_consumed_message(message_record, attrs) do
    message_record
    |> ConsumedMessage.changeset(attrs)
    |> @repo.update()
  end

  def get_consumed_message(message_params) do
    consumed_message_query(message_params)
    |> @repo.one()
  end

  def lock_message(%ConsumedMessage{} = consumed_message) do
    consumed_message_query(consumed_message)
    |> lock("FOR UPDATE")
    |> @repo.one()
  end

  defp consumed_message_query(%{uuid: uuid, queue: queue}) do
    from(m in ConsumedMessage,
      where: m.uuid == ^uuid,
      where: m.queue == ^queue
    )
  end
end
