defmodule NodepadApiWeb.DraftController do
  use NodepadApiWeb, :controller

  alias NodepadApi.{Workflows, Workspaces}
  alias NodepadApi.Auth.Guardian
  alias NodepadApi.Integrations.N8nClient

  def index(conn, %{"workflow_id" => workflow_id}) do
    drafts = Workflows.list_drafts(workflow_id)
    json(conn, drafts)
  end

  def create(conn, %{"workflow_id" => workflow_id} = params) do
    user = Guardian.Plug.current_resource(conn)

    case Workflows.create_draft(%{data: params["data"], workflow_id: workflow_id, user_id: user.id}) do
      {:ok, draft} -> conn |> put_status(:created) |> json(draft)
      {:error, changeset} -> conn |> put_status(:unprocessable_entity) |> json(%{errors: format_errors(changeset)})
    end
  end

  def push(conn, %{"id" => id}) do
    draft = Workflows.get_draft(id)
    workflow = Workflows.get_workflow(draft.workflow_id)
    connection = Workspaces.get_connection(workflow.connection_id)
    api_key = Workspaces.decrypt_api_key(connection)

    case N8nClient.update_workflow(connection.base_url, api_key, workflow.n8n_workflow_id, draft.data) do
      {:ok, _} ->
        Workflows.mark_draft_pushed(draft)
        json(conn, %{success: true})

      {:error, reason} ->
        conn |> put_status(:bad_gateway) |> json(%{error: inspect(reason)})
    end
  end

  def delete(conn, %{"id" => id}) do
    case Workflows.get_draft(id) do
      nil -> conn |> put_status(:not_found) |> json(%{error: "Draft not found"})
      draft ->
        Workflows.delete_draft(draft)
        send_resp(conn, :no_content, "")
    end
  end

  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)
  end
end
