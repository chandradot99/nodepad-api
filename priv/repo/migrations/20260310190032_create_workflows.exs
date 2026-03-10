defmodule NodepadApi.Repo.Migrations.CreateWorkflows do
  use Ecto.Migration

  def change do
    create table(:workflows, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :n8n_workflow_id, :string, null: false
      add :name, :string, null: false
      add :active, :boolean, default: false
      add :data, :map, null: false
      add :connection_id, references(:connections, type: :binary_id, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:workflows, [:connection_id])
    create unique_index(:workflows, [:connection_id, :n8n_workflow_id])
  end
end
