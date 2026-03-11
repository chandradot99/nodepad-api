defmodule NodepadApiWeb.ExtensionController do
  use NodepadApiWeb, :controller

  alias NodepadApi.Accounts
  alias NodepadApi.Workspaces

  # POST /api/extension-token — generate a new token (JWT auth)
  def generate_token(conn, _params) do
    user = Guardian.Plug.current_resource(conn)

    case Accounts.generate_extension_token(user) do
      {:ok, updated_user} ->
        json(conn, %{token: updated_user.extension_token})

      {:error, _changeset} ->
        conn |> put_status(:internal_server_error) |> json(%{error: "Failed to generate token"})
    end
  end

  # DELETE /api/extension-token — revoke token (JWT auth)
  def revoke_token(conn, _params) do
    user = Guardian.Plug.current_resource(conn)

    case Accounts.revoke_extension_token(user) do
      {:ok, _} -> send_resp(conn, :no_content, "")
      {:error, _} -> conn |> put_status(:internal_server_error) |> json(%{error: "Failed to revoke token"})
    end
  end

  # GET /api/extension-token/status — check if token exists (JWT auth)
  def token_status(conn, _params) do
    user = Guardian.Plug.current_resource(conn)
    has_token = not is_nil(user.extension_token)
    hint = if has_token, do: "···#{String.slice(user.extension_token, -6, 6)}", else: nil
    json(conn, %{has_token: has_token, hint: hint})
  end

  # POST /api/sync/nodes — sync node schemas (extension token auth)
  def sync_nodes(conn, %{"base_url" => base_url, "nodes" => nodes}) do
    user = conn.assigns.current_user

    # Find connection matching base_url for this user
    case Workspaces.get_connection_by_base_url(user.id, base_url) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "No connection found for #{base_url}. Make sure the n8n URL matches your workspace connection."})

      connection ->
        {upserted, _} = Workspaces.upsert_node_schemas(connection.id, nodes)
        json(conn, %{synced: upserted, connection_id: connection.id})
    end
  end

  def sync_nodes(conn, _params) do
    conn |> put_status(:bad_request) |> json(%{error: "Missing base_url or nodes"})
  end
end
