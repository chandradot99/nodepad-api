defmodule NodepadApi.Workspaces.Workspace do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "workspaces" do
    field :name, :string

    belongs_to :user, NodepadApi.Accounts.User
    has_many :connections, NodepadApi.Workspaces.Connection

    timestamps()
  end

  def changeset(workspace, attrs) do
    workspace
    |> cast(attrs, [:name, :user_id])
    |> validate_required([:name, :user_id])
  end
end
