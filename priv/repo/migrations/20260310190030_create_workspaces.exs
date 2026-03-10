defmodule NodepadApi.Repo.Migrations.CreateWorkspaces do
  use Ecto.Migration

  def change do
    create table(:workspaces, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:workspaces, [:user_id])
  end
end
