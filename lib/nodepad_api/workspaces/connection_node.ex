defmodule NodepadApi.Workspaces.ConnectionNode do
  use Ecto.Schema

  @primary_key false
  @foreign_key_type :binary_id

  schema "connection_nodes" do
    belongs_to :connection, NodepadApi.Workspaces.Connection
    belongs_to :node, NodepadApi.Workspaces.Node
  end
end
