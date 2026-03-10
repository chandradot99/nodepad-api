defmodule NodepadApi.Chat do
  import Ecto.Query
  alias NodepadApi.Repo
  alias NodepadApi.Chat.{Conversation, Message}

  def list_conversations(workflow_id, user_id) do
    Conversation
    |> where([c], c.workflow_id == ^workflow_id and c.user_id == ^user_id)
    |> order_by([c], desc: c.inserted_at)
    |> Repo.all()
  end

  def get_conversation(id), do: Repo.get(Conversation, id) |> Repo.preload(:messages)

  def create_conversation(attrs) do
    %Conversation{}
    |> Conversation.changeset(attrs)
    |> Repo.insert()
  end

  def list_messages(conversation_id) do
    Message
    |> where([m], m.conversation_id == ^conversation_id)
    |> order_by([m], asc: m.inserted_at)
    |> Repo.all()
  end

  def create_message(attrs) do
    %Message{}
    |> Message.changeset(attrs)
    |> Repo.insert()
  end
end
