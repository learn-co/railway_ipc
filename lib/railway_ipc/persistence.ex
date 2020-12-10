defmodule RailwayIpc.Persistence do
  @moduledoc false
  @behaviour RailwayIpc.PersistenceBehaviour
  @repo Application.get_env(:railway_ipc, :repo, RailwayIpc.Dev.Repo)
  alias RailwayIpc.Persistence.{
    PublishedMessage,
    ConsumedMessage,
    ConsumedMessageAdapter,
    PublishedMessageAdapter
  }

  alias RailwayIpc.{MessageConsumption, MessagePublishing}
  import Ecto.Query

  def insert_published_message(%MessagePublishing{
        exchange: exchange,
        queue: queue,
        outbound_message: outbound_message
      }) do
    {:ok, persistence_attrs} =
      outbound_message
      |> PublishedMessageAdapter.to_persistence(exchange, queue)

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
