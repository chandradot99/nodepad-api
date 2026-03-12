defmodule NodepadApi.Workspaces.CredentialType do
  use Ecto.Schema

  @derive {Jason.Encoder, only: [:id, :name, :display_name, :icon_url_light, :icon_url_dark, :documentation_url, :properties, :inserted_at, :updated_at]}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "credential_types" do
    field :name, :string
    field :display_name, :string
    field :icon_url_light, :string
    field :icon_url_dark, :string
    field :documentation_url, :string
    field :properties, {:array, :map}, default: []

    timestamps()
  end
end
