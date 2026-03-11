defmodule NodepadApi.Workspaces do
  import Ecto.Query
  alias NodepadApi.Repo
  alias NodepadApi.Workspaces.{Workspace, Connection}

  def list_workspaces(user_id) do
    Workspace
    |> where([w], w.user_id == ^user_id)
    |> Repo.all()
  end

  def get_workspace(id, user_id) do
    Workspace
    |> where([w], w.id == ^id and w.user_id == ^user_id)
    |> Repo.one()
  end

  def create_workspace(attrs) do
    %Workspace{}
    |> Workspace.changeset(attrs)
    |> Repo.insert()
  end

  def update_workspace(%Workspace{} = workspace, attrs) do
    workspace
    |> Workspace.update_changeset(attrs)
    |> Repo.update()
  end

  def delete_workspace(%Workspace{} = workspace), do: Repo.delete(workspace)

  # Connections

  def list_connections(workspace_id) do
    Connection
    |> where([c], c.workspace_id == ^workspace_id)
    |> Repo.all()
  end

  def get_connection(id), do: Repo.get(Connection, id)

  # Fetch a connection only if it belongs to a workspace owned by user_id
  def get_connection_for_user(id, user_id) do
    Connection
    |> join(:inner, [c], w in Workspace, on: c.workspace_id == w.id)
    |> where([c, w], c.id == ^id and w.user_id == ^user_id)
    |> Repo.one()
  end

  def create_connection(attrs) do
    %Connection{}
    |> Connection.changeset(attrs)
    |> Repo.insert()
  end

  def update_connection(%Connection{} = connection, attrs) do
    connection
    |> Connection.update_changeset(attrs)
    |> Repo.update()
  end

  def delete_connection(%Connection{} = connection), do: Repo.delete(connection)

  def decrypt_api_key(%Connection{encrypted_api_key: key}) do
    NodepadApi.Encryption.decrypt(key)
  end
end
