defmodule NodepadApiWeb.ChatController do
  use NodepadApiWeb, :controller

  alias NodepadApi.{Chat, Workflows, Workspaces}
  alias NodepadApi.Auth.Guardian
  alias NodepadApi.Integrations.{ClaudeClient, N8nClient}

  def create_conversation(conn, %{"workflow_id" => workflow_id} = params) do
    user = Guardian.Plug.current_resource(conn)

    case Chat.create_conversation(%{title: params["title"], workflow_id: workflow_id, user_id: user.id}) do
      {:ok, conversation} -> conn |> put_status(:created) |> json(conversation)
      {:error, changeset} -> conn |> put_status(:unprocessable_entity) |> json(%{errors: format_errors(changeset)})
    end
  end

  def list_conversations(conn, %{"workflow_id" => workflow_id}) do
    user = Guardian.Plug.current_resource(conn)
    conversations = Chat.list_conversations(workflow_id, user.id)
    json(conn, conversations)
  end

  def list_messages(conn, %{"conversation_id" => conversation_id}) do
    messages = Chat.list_messages(conversation_id)
    json(conn, messages)
  end

  def send_message(conn, %{"conversation_id" => conversation_id, "content" => content, "claude_api_key" => claude_api_key}) do
    _user = Guardian.Plug.current_resource(conn)
    conversation = Chat.get_conversation(conversation_id)
    workflow = Workflows.get_workflow(conversation.workflow_id)
    connection = Workspaces.get_connection(workflow.connection_id)
    api_key = Workspaces.decrypt_api_key(connection)

    # Fetch available credentials from n8n (best-effort, don't fail if unavailable)
    credentials_context =
      case N8nClient.list_credentials(connection.base_url, api_key) do
        {:ok, %{"data" => creds}} ->
          cred_lines = Enum.map(creds, fn c -> "- #{c["name"]} (type: #{c["type"]}, id: #{c["id"]})" end)
          "\n\nAvailable credentials in this n8n instance:\n#{Enum.join(cred_lines, "\n")}"
        _ ->
          ""
      end

    # Save user message
    {:ok, _} = Chat.create_message(%{role: "user", content: content, conversation_id: conversation_id})

    # Build message history for Claude
    messages = Enum.map(conversation.messages, fn m -> %{role: m.role, content: m.content} end)
    messages = messages ++ [%{role: "user", content: content}]

    system_prompt = """
    You are an expert n8n workflow assistant. You help users modify and improve their n8n workflows.
    When asked to make changes, respond with the complete updated workflow JSON inside a ```json``` code block.
    When adding nodes that require credentials, use the available credentials listed below — match by type.
    Current workflow:
    #{Jason.encode!(workflow.data, pretty: true)}#{credentials_context}
    """

    case ClaudeClient.chat(claude_api_key, messages, system_prompt) do
      {:ok, reply} ->
        {:ok, _} = Chat.create_message(%{role: "assistant", content: reply, conversation_id: conversation_id})
        json(conn, %{reply: reply})

      {:error, reason} ->
        conn |> put_status(:bad_gateway) |> json(%{error: inspect(reason)})
    end
  end

  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)
  end
end
