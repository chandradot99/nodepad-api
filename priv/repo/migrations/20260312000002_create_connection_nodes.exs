defmodule NodepadApi.Repo.Migrations.CreateConnectionNodes do
  use Ecto.Migration

  def up do
    create table(:connection_nodes, primary_key: false) do
      add :connection_id, references(:connections, type: :binary_id, on_delete: :delete_all), null: false
      add :node_id, references(:nodes, type: :binary_id, on_delete: :delete_all), null: false
    end

    execute "ALTER TABLE connection_nodes ADD PRIMARY KEY (connection_id, node_id)"
    create index(:connection_nodes, [:node_id])
  end

  def down do
    drop table(:connection_nodes)
  end
end
