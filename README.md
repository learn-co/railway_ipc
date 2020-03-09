# RailwayIpc

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `railway_ipc` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:railway_ipc, "~> 0.1.0"}
  ]
end
```

## Getting Started

Configure Railway to work with your Repo. Add the following to your `config/config.exs`:

```elixir
config :railway_ipc,
  repo: ApplicationName.Repo
```

Run the mix task to generate the migrations to add the published messages and consumed messages tables to your app's DB:

```bash
mix railway_ipc.generate_migrations ./path/to/migration/directory
mix ecto.migrate
```

> Note: Path to migration directory defaults to `./priv/repo/migrations` if none is passed in.

**If there are issues running the migration or deploying the migration, try manually writing the name of the migration module (not the file) to avoid using interpolation.**

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm).
Once published, the docs can
be found at [https://hexdocs.pm/railway_ipc](https://hexdocs.pm/railway_ipc).

## Consuming the same message on multiple queues

Out of the box, Railway can handle storing the same messages muletiple times if it's consumed on multiple queues. If you are upgrading Railway from 2.1 or earlier, you will need to run the following migration to make `uuid` and `queue` a combined primary key for the consumed messages table.

```elixir
defmodule YOUR_APP_NAME_HERE.Repo.Migrations.UpdateRailwayMessagePKey do
  use Ecto.Migration

  import Ecto.Query, only: [from: 2]
  alias Registrar.Repo

  def up do
    alter table(:railway_ipc_consumed_messages) do
      add :new_uuid, :uuid
    end

    flush()

    from(m in "railway_ipc_consumed_messages", update: [set: [new_uuid: m.uuid]])
    |> Repo.update_all([])

    alter table(:railway_ipc_consumed_messages) do
      remove :uuid
      modify :queue, :string, primary_key: true, null: false
      modify :new_uuid, :uuid, primary_key: true, null: false
    end

    rename(table(:railway_ipc_consumed_messages), :new_uuid, to: :uuid)

    create unique_index(
      "railway_ipc_consumed_messages",
      [:uuid, :queue],
      name: :railway_ipc_consumed_messages_uniqueness_index
    )
  end

  def down do
    alter table(:railway_ipc_consumed_messages) do
      add :old_uuid, :uuid
      add :old_queue, :string
    end

    flush()

    from(m in "railway_ipc_consumed_messages", update: [set: [old_uuid: m.uuid, old_queue: m.queue]])
    |> Repo.update_all([])

    alter table(:railway_ipc_consumed_messages) do
      remove :uuid
      remove :queue
      modify :old_uuid, :uuid, primary_key: true, null: false
      modify :old_queue, :string, null: false
    end

    rename(table(:railway_ipc_consumed_messages), :old_uuid, to: :uuid)
    rename(table(:railway_ipc_consumed_messages), :old_queue, to: :queue)
  end
end
```

For more information on this process, check out this blogpost: https://niallburkley.com/blog/changing-primary-keys-in-ecto/
