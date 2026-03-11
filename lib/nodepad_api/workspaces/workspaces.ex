defmodule NodepadApi.Workspaces do
  import Ecto.Query
  alias NodepadApi.Repo
  alias NodepadApi.Workspaces.{Workspace, Connection, NodeSchema}

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

  # Node schemas

  def get_connection_by_base_url(user_id, base_url) do
    normalized = String.trim_trailing(base_url, "/")

    Connection
    |> join(:inner, [c], w in Workspace, on: c.workspace_id == w.id)
    |> where([c, w], w.user_id == ^user_id)
    |> where([c], fragment("rtrim(?, '/')", c.base_url) == ^normalized)
    |> Repo.one()
  end

  def upsert_node_schemas(connection_id, nodes) when is_list(nodes) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    records =
      nodes
      |> Enum.map(fn node ->
        %{
          id: Ecto.UUID.generate(),
          connection_id: connection_id,
          name: node["name"],
          display_name: node["displayName"],
          group: node["group"] || [],
          description: node["description"],
          icon_url: parse_icon_url(node["iconUrl"]),
          version: parse_version(node["version"]),
          credentials: node["credentials"] || [],
          properties: node["properties"] || [],
          codex: node["codex"] || %{},
          inserted_at: now,
          updated_at: now
        }
      end)
      |> Enum.reject(fn r -> is_nil(r.name) end)
      |> Enum.uniq_by(fn r -> r.name end)

    result =
      Repo.insert_all(
        NodeSchema,
        records,
        on_conflict: {:replace, [:display_name, :group, :description, :icon_url, :version, :credentials, :properties, :codex, :updated_at]},
        conflict_target: [:connection_id, :name],
        returning: [:id]
      )

    result
  end

  defp parse_version(v) when is_integer(v), do: v
  defp parse_version(v) when is_float(v), do: trunc(v)
  defp parse_version(v) when is_list(v) and length(v) > 0, do: parse_version(List.last(v))
  defp parse_version(_), do: nil

  defp parse_icon_url(url) when is_binary(url), do: url
  defp parse_icon_url(%{"light" => url}) when is_binary(url), do: url
  defp parse_icon_url(%{"dark" => url}) when is_binary(url), do: url
  defp parse_icon_url(_), do: nil
end
