defmodule NodepadApi.Workflows do
  import Ecto.Query
  alias NodepadApi.Repo
  alias NodepadApi.Workflows.{Workflow, Draft}

  def list_workflows(connection_id) do
    Workflow
    |> where([w], w.connection_id == ^connection_id)
    |> Repo.all()
  end

  def get_workflow(id), do: Repo.get(Workflow, id)

  def upsert_workflow(attrs) do
    case Repo.get_by(Workflow, connection_id: attrs.connection_id, n8n_workflow_id: attrs.n8n_workflow_id) do
      nil -> %Workflow{}
      workflow -> workflow
    end
    |> Workflow.changeset(attrs)
    |> Repo.insert_or_update()
  end

  # Drafts

  def list_drafts(workflow_id) do
    Draft
    |> where([d], d.workflow_id == ^workflow_id)
    |> order_by([d], desc: d.inserted_at)
    |> Repo.all()
  end

  def get_draft(id), do: Repo.get(Draft, id)

  def create_draft(attrs) do
    %Draft{}
    |> Draft.changeset(attrs)
    |> Repo.insert()
  end

  def mark_draft_pushed(%Draft{} = draft) do
    draft
    |> Draft.changeset(%{status: "pushed"})
    |> Repo.update()
  end

  def delete_draft(%Draft{} = draft), do: Repo.delete(draft)
end
