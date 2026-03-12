defmodule NodepadApi.Repo.Migrations.CreateNodes do
  use Ecto.Migration

  def change do
    create table(:nodes, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :version, :integer, null: false, default: 1
      add :display_name, :string
      add :group, {:array, :string}, default: []
      add :description, :text
      add :icon_url, :string
      add :is_community, :boolean, default: false, null: false
      add :credentials, :jsonb, default: "[]"
      add :properties, :jsonb, default: "[]"
      add :codex, :jsonb, default: "{}"

      timestamps()
    end

    create unique_index(:nodes, [:name, :version])
    create index(:nodes, [:is_community])
  end
end
