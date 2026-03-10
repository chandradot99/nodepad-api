defmodule NodepadApiWeb.ConnectionController do
  use NodepadApiWeb, :controller

  alias NodepadApi.Workspaces
  alias NodepadApi.Integrations.N8nClient

  def index(conn, %{"workspace_id" => workspace_id}) do
    connections = Workspaces.list_connections(workspace_id)
    json(conn, connections)
  end

  def create(conn, %{"workspace_id" => workspace_id} = params) do
    attrs = Map.put(params, "workspace_id", workspace_id)

    case Workspaces.create_connection(attrs) do
      {:ok, connection} ->
        conn |> put_status(:created) |> json(%{id: connection.id, name: connection.name, base_url: connection.base_url})

      {:error, changeset} ->
        conn |> put_status(:unprocessable_entity) |> json(%{errors: format_errors(changeset)})
    end
  end

  def test(conn, %{"id" => id}) do
    connection = Workspaces.get_connection(id)
    api_key = Workspaces.decrypt_api_key(connection)

    case N8nClient.list_workflows(connection.base_url, api_key) do
      {:ok, _} -> json(conn, %{success: true, message: "Connection successful"})
      {:error, reason} -> conn |> put_status(:bad_gateway) |> json(%{success: false, error: inspect(reason)})
    end
  end

  def credentials(conn, %{"id" => id}) do
    connection = Workspaces.get_connection(id)
    api_key = Workspaces.decrypt_api_key(connection)

    creds =
      case N8nClient.list_credentials(connection.base_url, api_key) do
        {:ok, %{"data" => data}} -> Enum.map(data, &Map.take(&1, ["id", "name", "type"]))
        _ -> []
      end

    json(conn, creds)
  end

  def delete(conn, %{"id" => id}) do
    case Workspaces.get_connection(id) do
      nil -> conn |> put_status(:not_found) |> json(%{error: "Connection not found"})
      connection ->
        Workspaces.delete_connection(connection)
        send_resp(conn, :no_content, "")
    end
  end

  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)
  end
end
