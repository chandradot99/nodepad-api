defmodule NodepadApi.Repo.Migrations.CreateConnectionNodeSchemas do
  use Ecto.Migration

  def change do
    create table(:connection_node_schemas, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :connection_id, references(:connections, type: :binary_id, on_delete: :delete_all), null: false
      add :name, :string, null: false
      add :display_name, :string
      add :group, {:array, :string}, default: []
      add :description, :text
      add :icon_url, :text
      add :version, :integer
      add :credentials, :map, default: %{}
      add :properties, :map, default: %{}
      add :codex, :map, default: %{}

      timestamps()
    end

    create unique_index(:connection_node_schemas, [:connection_id, :name])
    create index(:connection_node_schemas, [:connection_id])
  end
end
