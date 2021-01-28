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

  alias RailwayIpc.Dev.Repo

  using do
    quote do
      alias RailwayIpc.Dev.Repo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import RailwayIpc.DataCase
    end
  end

  setup tags do
    # credo:disable-for-next-line Credo.Check.Design.AliasUsage
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(RailwayIpc.Dev.Repo)

    unless tags[:async] do
      # credo:disable-for-next-line Credo.Check.Design.AliasUsage
      Ecto.Adapters.SQL.Sandbox.mode(RailwayIpc.Dev.Repo, {:shared, self()})
    end

    :ok
  end

  @doc """
  A helper that transforms changeset errors into a map of messages.

      assert {:error, changeset} = Accounts.create_user(%{password: "short"})
      assert "password is too short" in errors_on(changeset).password
      assert %{password: ["password is too short"]} = errors_on(changeset)

  """
  def errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end

  @doc """
  Retrieves the current row count for the given table. Since SQL `count`
  requires a column, we have to provide that as well. This defaults the
  column name to UUID since all Railway tables have it, but you can override
  it if you want.

  """
  def row_count(table, column \\ :uuid) do
    Repo.aggregate(table, :count, column)
  end
end
