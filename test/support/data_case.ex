defmodule RailwayIpc.DataCase do
  @moduledoc """
  This module defines the setup for tests requiring
  access to the application's data layer.

  You may define functions here to be used as helpers in
  your tests.

  Finally, if the test case interacts with the database,
  it cannot be async. For this reason, every test runs
  inside a transaction which is reset at the beginning
  of the test unless the test case is marked as async.
  """

  use ExUnit.CaseTemplate

  alias Ecto.Adapters.SQL.Sandbox
  alias RailwayIpc.Dev.Repo
  alias RailwayIpc.Storage.DB.PublishedMessage

  using do
    quote do
      import RailwayIpc.DataCase
    end
  end

  setup context do
    :ok = Sandbox.checkout(Repo)

    unless context[:async] do
      Sandbox.mode(Repo, {:shared, self()})
    end

    context
  end

  @doc """
  Retrieves the current row count for the given table.

  Since SQL `count` requires a column, we have to provide that as well. This
  defaults the column name to UUID since all Railway tables have it, but you
  can override it if you want.

  """
  def row_count(table, column \\ :uuid) do
    Repo.aggregate(table, :count, column)
  end

  @doc """
  Retrieves a published message by UUID, raises an error if not found.

  """
  def get_published_message!(uuid) do
    Repo.get!(PublishedMessage, uuid)
  end
end
