defmodule NodepadApi.Workflows.Draft do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:id, :data, :status, :workflow_id, :user_id, :inserted_at, :updated_at]}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @valid_statuses ~w(pending pushed)

  schema "drafts" do
    field :data, :map
    field :status, :string, default: "pending"

    belongs_to :workflow, NodepadApi.Workflows.Workflow
    belongs_to :user, NodepadApi.Accounts.User

    timestamps()
  end

  def changeset(draft, attrs) do
    draft
    |> cast(attrs, [:data, :status, :workflow_id, :user_id])
    |> validate_required([:data, :workflow_id, :user_id])
    |> validate_inclusion(:status, @valid_statuses)
  end
end
