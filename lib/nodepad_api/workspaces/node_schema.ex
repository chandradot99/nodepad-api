defmodule NodepadApi.Workspaces.NodeSchema do
  use Ecto.Schema

  @derive {Jason.Encoder, only: [:id, :connection_id, :name, :display_name, :group, :description, :icon_url, :version, :credentials, :properties, :codex, :inserted_at, :updated_at]}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "connection_node_schemas" do
    field :name, :string
    field :display_name, :string
    field :group, {:array, :string}, default: []
    field :description, :string
    field :icon_url, :string
    field :version, :integer
    field :credentials, {:array, :map}, default: []
    field :properties, {:array, :map}, default: []
    field :codex, :map, default: %{}

    belongs_to :connection, NodepadApi.Workspaces.Connection

    timestamps()
  end
end
