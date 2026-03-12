defmodule NodepadApi.Repo.Migrations.DropConnectionNodeSchemas do
  use Ecto.Migration

  def change do
    drop table(:connection_node_schemas)
  end
end
