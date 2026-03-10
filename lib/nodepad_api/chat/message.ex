defmodule NodepadApi.Chat.Message do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:id, :role, :content, :conversation_id, :inserted_at, :updated_at]}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @valid_roles ~w(user assistant)

  schema "messages" do
    field :role, :string
    field :content, :string

    belongs_to :conversation, NodepadApi.Chat.Conversation

    timestamps()
  end

  def changeset(message, attrs) do
    message
    |> cast(attrs, [:role, :content, :conversation_id])
    |> validate_required([:role, :content, :conversation_id])
    |> validate_inclusion(:role, @valid_roles)
  end
end
