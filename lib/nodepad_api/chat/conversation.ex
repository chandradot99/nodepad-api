defmodule NodepadApi.Chat.Conversation do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:id, :title, :workflow_id, :user_id, :inserted_at, :updated_at]}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "conversations" do
    field :title, :string

    belongs_to :workflow, NodepadApi.Workflows.Workflow
    belongs_to :user, NodepadApi.Accounts.User
    has_many :messages, NodepadApi.Chat.Message

    timestamps()
  end

  def changeset(conversation, attrs) do
    conversation
    |> cast(attrs, [:title, :workflow_id, :user_id])
    |> validate_required([:workflow_id, :user_id])
  end
end
