defmodule NodepadApi.Repo.Migrations.AddExtensionTokenToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :extension_token, :string, null: true
    end

    create unique_index(:users, [:extension_token])
  end
end
