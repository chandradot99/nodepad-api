defmodule NodepadApi.Repo.Migrations.CreateSavedCredentials do
  use Ecto.Migration

  def change do
    create table(:saved_credentials, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :connection_id, references(:connections, type: :binary_id, on_delete: :delete_all), null: false
      add :n8n_id, :string, null: false
      add :name, :string
      add :type, :string

      timestamps()
    end

    create unique_index(:saved_credentials, [:connection_id, :n8n_id])
    create index(:saved_credentials, [:type])
  end
end
