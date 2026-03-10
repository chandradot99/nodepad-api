defmodule NodepadApiWeb.WorkflowController do
  use NodepadApiWeb, :controller

  alias NodepadApi.{Workflows, Workspaces}
  alias NodepadApi.Integrations.N8nClient

  def index(conn, %{"connection_id" => connection_id}) do
    connection = Workspaces.get_connection(connection_id)
    api_key = Workspaces.decrypt_api_key(connection)

    case N8nClient.list_workflows(connection.base_url, api_key) do
      {:ok, %{"data" => workflows}} ->
        # Sync to local DB and return
        synced = Enum.map(workflows, fn w ->
          {:ok, workflow} = Workflows.upsert_workflow(%{
            n8n_workflow_id: w["id"],
            name: w["name"],
            active: w["active"],
            data: w,
            connection_id: connection_id
          })
          workflow
        end)
        json(conn, synced)

      {:error, reason} ->
        conn |> put_status(:bad_gateway) |> json(%{error: inspect(reason)})
    end
  end

  def show(conn, %{"id" => id}) do
    case Workflows.get_workflow(id) do
      nil -> conn |> put_status(:not_found) |> json(%{error: "Workflow not found"})
      workflow -> json(conn, workflow)
    end
  end

  def push(conn, %{"id" => id}) do
    workflow = Workflows.get_workflow(id)
    connection = Workspaces.get_connection(workflow.connection_id)
    api_key = Workspaces.decrypt_api_key(connection)

    case N8nClient.update_workflow(connection.base_url, api_key, workflow.n8n_workflow_id, workflow.data) do
      {:ok, _} -> json(conn, %{success: true})
      {:error, reason} -> conn |> put_status(:bad_gateway) |> json(%{error: inspect(reason)})
    end
  end
end
