defmodule NodepadApi.Repo.Migrations.CreateDrafts do
  use Ecto.Migration

  def change do
    create table(:drafts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :data, :map, null: false
      add :status, :string, default: "pending", null: false
      add :workflow_id, references(:workflows, type: :binary_id, on_delete: :delete_all), null: false
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:drafts, [:workflow_id])
    create index(:drafts, [:user_id])
  end
end
