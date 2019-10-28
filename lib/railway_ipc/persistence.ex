defmodule RailwayIpc.Persistence do
  @behaviour RailwayIpc.PersistenceBehaviour
  @repo Application.get_env(:railway_ipc, :repo, RailwayIpc.Dev.Repo)
  alias RailwayIpc.Persistence.PublishedMessage
  alias RailwayIpc.Persistence.ConsumedMessage
  alias RailwayIpc.MessageConsumption
  alias RailwayIpc.Persistence.ConsumedMessageAdapter
  alias RailwayIpc.Persistence.PublishedMessageAdapter
  import Ecto.Query

  def insert_published_message(message, exchange) do
    {:ok, persistence_attrs} =
      message
      |> PublishedMessageAdapter.to_persistence(exchange)

    %PublishedMessage{}
    |> PublishedMessage.changeset(persistence_attrs)
    |> @repo.insert()
  end

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

  def get_published_message(message_uuid) do
    query =
      from(m in PublishedMessage,
        where: m.uuid == ^message_uuid
      )

    @repo.one(query)
  end

  def get_consumed_message(message_uuid) do
    consumed_message_query(message_uuid)
    |> @repo.one()
  end

  def lock_message(%ConsumedMessage{uuid: uuid}) do
    consumed_message_query(uuid)
    |> lock("FOR UPDATE")
    |> @repo.one()
  end

  def consumed_message_query(uuid) do
    from(m in ConsumedMessage,
      where: m.uuid == ^uuid
    )
  end
end
