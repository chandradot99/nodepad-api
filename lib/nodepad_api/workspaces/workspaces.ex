defmodule NodepadApi.Workspaces do
  import Ecto.Query
  alias NodepadApi.Repo
  alias NodepadApi.Workspaces.{Workspace, Connection, Node, ConnectionNode, CredentialType, SavedCredential}

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

  def get_connection_by_base_url(user_id, base_url) do
    normalized = String.trim_trailing(base_url, "/")

    Connection
    |> join(:inner, [c], w in Workspace, on: c.workspace_id == w.id)
    |> where([c, w], w.user_id == ^user_id)
    |> where([c], fragment("rtrim(?, '/')", c.base_url) == ^normalized)
    |> Repo.one()
  end

  # Nodes

  def list_nodes(connection_id) do
    Node
    |> join(:inner, [n], cn in ConnectionNode, on: cn.node_id == n.id)
    |> where([n, cn], cn.connection_id == ^connection_id)
    |> select([n], %{
      id: n.id,
      name: n.name,
      version: n.version,
      display_name: n.display_name,
      group: n.group,
      description: n.description,
      icon_url: n.icon_url,
      is_community: n.is_community,
      codex: n.codex
    })
    |> order_by([n], asc: n.display_name)
    |> Repo.all()
  end

  def upsert_nodes(connection_id, nodes) when is_list(nodes) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    records =
      nodes
      |> Enum.reject(fn n -> is_nil(n["name"]) end)
      |> Enum.uniq_by(fn n -> {n["name"], parse_version(n["version"])} end)
      |> Enum.map(fn node ->
        name = node["name"]
        version = parse_version(node["version"])

        %{
          id: Ecto.UUID.generate(),
          name: name,
          version: version,
          display_name: node["displayName"],
          group: node["group"] || [],
          description: node["description"],
          icon_url: parse_icon_url(node["iconUrl"]),
          is_community: not String.starts_with?(name, ["n8n-nodes-base.", "@n8n/n8n-nodes-langchain."]),
          credentials: node["credentials"] || [],
          properties: node["properties"] || [],
          codex: node["codex"] || %{},
          inserted_at: now,
          updated_at: now
        }
      end)

    {upserted, node_rows} =
      Repo.insert_all(
        Node,
        records,
        on_conflict: {:replace, [:display_name, :group, :description, :icon_url, :is_community, :credentials, :properties, :codex, :updated_at]},
        conflict_target: [:name, :version],
        returning: [:id]
      )

    # Rebuild connection_nodes for this connection
    # ON CONFLICT DO UPDATE ... RETURNING returns all rows (inserted + updated)
    node_ids = Enum.map(node_rows, & &1.id)

    Repo.delete_all(from cn in ConnectionNode, where: cn.connection_id == ^connection_id)

    junction_rows = Enum.map(node_ids, fn node_id ->
      %{connection_id: connection_id, node_id: node_id}
    end)

    Repo.insert_all(ConnectionNode, junction_rows, on_conflict: :nothing)

    {upserted, length(junction_rows)}
  end

  # Credential types

  def upsert_credential_types(credential_types) when is_list(credential_types) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    records =
      credential_types
      |> Enum.reject(fn ct -> is_nil(ct["name"]) end)
      |> Enum.uniq_by(fn ct -> ct["name"] end)
      |> Enum.map(fn ct ->
        {light, dark} = parse_icon_url_pair(ct["iconUrl"])

        %{
          id: Ecto.UUID.generate(),
          name: ct["name"],
          display_name: ct["displayName"],
          icon_url_light: light,
          icon_url_dark: dark,
          documentation_url: ct["documentationUrl"],
          properties: ct["properties"] || [],
          inserted_at: now,
          updated_at: now
        }
      end)

    {upserted, _} =
      Repo.insert_all(
        CredentialType,
        records,
        on_conflict: {:replace, [:display_name, :icon_url_light, :icon_url_dark, :documentation_url, :properties, :updated_at]},
        conflict_target: [:name]
      )

    upserted
  end

  # Saved credentials

  def upsert_saved_credentials(connection_id, credentials) when is_list(credentials) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    records =
      credentials
      |> Enum.reject(fn c -> is_nil(c["id"]) end)
      |> Enum.uniq_by(fn c -> c["id"] end)
      |> Enum.map(fn cred ->
        %{
          id: Ecto.UUID.generate(),
          connection_id: connection_id,
          n8n_id: cred["id"],
          name: cred["name"],
          type: cred["type"],
          inserted_at: now,
          updated_at: now
        }
      end)

    n8n_ids = Enum.map(records, & &1.n8n_id)

    # Delete rows not in the current sync list
    Repo.delete_all(
      from sc in SavedCredential,
      where: sc.connection_id == ^connection_id and sc.n8n_id not in ^n8n_ids
    )

    {upserted, _} =
      Repo.insert_all(
        SavedCredential,
        records,
        on_conflict: {:replace, [:name, :type, :updated_at]},
        conflict_target: [:connection_id, :n8n_id]
      )

    upserted
  end

  def list_saved_credentials(connection_id) do
    SavedCredential
    |> where([sc], sc.connection_id == ^connection_id)
    |> join(:left, [sc], ct in CredentialType, on: ct.name == sc.type)
    |> select([sc, ct], %{
      id: sc.id,
      connection_id: sc.connection_id,
      n8n_id: sc.n8n_id,
      name: sc.name,
      type: sc.type,
      icon_url_light: ct.icon_url_light,
      icon_url_dark: ct.icon_url_dark,
      inserted_at: sc.inserted_at,
      updated_at: sc.updated_at
    })
    |> order_by([sc], asc: sc.name)
    |> Repo.all()
  end

  # Private helpers

  defp parse_version(v) when is_integer(v), do: v
  defp parse_version(v) when is_float(v), do: trunc(v)
  defp parse_version(v) when is_list(v) and length(v) > 0, do: parse_version(List.last(v))
  defp parse_version(_), do: 1

  defp parse_icon_url(url) when is_binary(url), do: url
  defp parse_icon_url(%{"light" => url}) when is_binary(url), do: url
  defp parse_icon_url(%{"dark" => url}) when is_binary(url), do: url
  defp parse_icon_url(_), do: nil

  defp parse_icon_url_pair(url) when is_binary(url), do: {url, url}
  defp parse_icon_url_pair(%{"light" => l, "dark" => d}), do: {l, d}
  defp parse_icon_url_pair(%{"light" => l}), do: {l, l}
  defp parse_icon_url_pair(%{"dark" => d}), do: {d, d}
  defp parse_icon_url_pair(_), do: {nil, nil}
end
