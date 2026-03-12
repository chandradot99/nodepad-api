defmodule NodepadApi.Workspaces.SavedCredential do
  use Ecto.Schema

  @derive {Jason.Encoder, only: [:id, :connection_id, :n8n_id, :name, :type, :inserted_at, :updated_at]}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "saved_credentials" do
    field :n8n_id, :string
    field :name, :string
    field :type, :string

    belongs_to :connection, NodepadApi.Workspaces.Connection

    timestamps()
  end
end
