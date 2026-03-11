defmodule NodepadApiWeb.WorkspaceController do
  use NodepadApiWeb, :controller

  alias NodepadApi.Workspaces
  alias NodepadApi.Auth.Guardian

  def index(conn, _params) do
    user = Guardian.Plug.current_resource(conn)
    workspaces = Workspaces.list_workspaces(user.id)
    json(conn, workspaces)
  end

  def create(conn, params) do
    user = Guardian.Plug.current_resource(conn)

    case Workspaces.create_workspace(Map.put(params, "user_id", user.id)) do
      {:ok, workspace} ->
        conn |> put_status(:created) |> json(workspace)

      {:error, changeset} ->
        conn |> put_status(:unprocessable_entity) |> json(%{errors: format_errors(changeset)})
    end
  end

  def update(conn, %{"id" => id} = params) do
    user = Guardian.Plug.current_resource(conn)

    case Workspaces.get_workspace(id, user.id) do
      nil ->
        conn |> put_status(:not_found) |> json(%{error: "Workspace not found"})

      workspace ->
        case Workspaces.update_workspace(workspace, params) do
          {:ok, updated} ->
            json(conn, updated)

          {:error, changeset} ->
            conn |> put_status(:unprocessable_entity) |> json(%{errors: format_errors(changeset)})
        end
    end
  end

  def delete(conn, %{"id" => id}) do
    user = Guardian.Plug.current_resource(conn)

    case Workspaces.get_workspace(id, user.id) do
      nil ->
        conn |> put_status(:not_found) |> json(%{error: "Workspace not found"})

      workspace ->
        Workspaces.delete_workspace(workspace)
        send_resp(conn, :no_content, "")
    end
  end

  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)
  end
end
