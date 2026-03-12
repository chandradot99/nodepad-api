defmodule NodepadApi.Workspaces.Node do
  use Ecto.Schema

  @derive {Jason.Encoder, only: [:id, :name, :version, :display_name, :group, :description, :icon_url, :is_community, :credentials, :properties, :codex, :inserted_at, :updated_at]}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "nodes" do
    field :name, :string
    field :version, :integer, default: 1
    field :display_name, :string
    field :group, {:array, :string}, default: []
    field :description, :string
    field :icon_url, :string
    field :is_community, :boolean, default: false
    field :credentials, {:array, :map}, default: []
    field :properties, {:array, :map}, default: []
    field :codex, :map, default: %{}

    many_to_many :connections, NodepadApi.Workspaces.Connection,
      join_through: NodepadApi.Workspaces.ConnectionNode

    timestamps()
  end
end
