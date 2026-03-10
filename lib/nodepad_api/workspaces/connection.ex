defmodule NodepadApi.Workspaces.Connection do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "connections" do
    field :name, :string
    field :base_url, :string
    field :api_key, :string, virtual: true
    field :encrypted_api_key, :string

    belongs_to :workspace, NodepadApi.Workspaces.Workspace
    has_many :workflows, NodepadApi.Workflows.Workflow

    timestamps()
  end

  def changeset(connection, attrs) do
    connection
    |> cast(attrs, [:name, :base_url, :api_key, :workspace_id])
    |> validate_required([:name, :base_url, :api_key, :workspace_id])
    |> validate_format(:base_url, ~r/^https?:\/\//, message: "must be a valid URL")
    |> encrypt_api_key()
  end

  defp encrypt_api_key(%Ecto.Changeset{valid?: true, changes: %{api_key: key}} = changeset) do
    put_change(changeset, :encrypted_api_key, NodepadApi.Encryption.encrypt(key))
  end

  defp encrypt_api_key(changeset), do: changeset
end
