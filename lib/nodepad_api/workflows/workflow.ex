defmodule NodepadApi.Workflows.Workflow do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:id, :n8n_workflow_id, :name, :active, :data, :connection_id, :inserted_at, :updated_at]}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "workflows" do
    field :n8n_workflow_id, :string
    field :name, :string
    field :active, :boolean, default: false
    field :data, :map

    belongs_to :connection, NodepadApi.Workspaces.Connection
    has_many :drafts, NodepadApi.Workflows.Draft
    has_many :conversations, NodepadApi.Chat.Conversation

    timestamps()
  end

  def changeset(workflow, attrs) do
    workflow
    |> cast(attrs, [:n8n_workflow_id, :name, :active, :data, :connection_id])
    |> validate_required([:n8n_workflow_id, :name, :data, :connection_id])
    |> unique_constraint([:connection_id, :n8n_workflow_id])
  end
end
