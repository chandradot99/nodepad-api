defmodule NodepadApi.Repo.Migrations.CreateCredentialTypes do
  use Ecto.Migration

  def change do
    create table(:credential_types, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :display_name, :string
      add :icon_url_light, :string
      add :icon_url_dark, :string
      add :documentation_url, :string
      add :properties, :jsonb, default: "[]"

      timestamps()
    end

    create unique_index(:credential_types, [:name])
  end
end
