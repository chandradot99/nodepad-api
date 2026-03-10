defmodule NodepadApi.Integrations.N8nClient do
  @moduledoc "HTTP client for n8n API"

  def list_workflows(base_url, api_key) do
    client(base_url, api_key)
    |> Req.get(url: "/api/v1/workflows")
    |> handle_response()
  end

  def get_workflow(base_url, api_key, workflow_id) do
    client(base_url, api_key)
    |> Req.get(url: "/api/v1/workflows/#{workflow_id}")
    |> handle_response()
  end

  def update_workflow(base_url, api_key, workflow_id, data) do
    client(base_url, api_key)
    |> Req.put(url: "/api/v1/workflows/#{workflow_id}", json: data)
    |> handle_response()
  end

  def list_credentials(base_url, api_key) do
    client(base_url, api_key)
    |> Req.get(url: "/api/v1/credentials")
    |> handle_response()
  end

  def activate_workflow(base_url, api_key, workflow_id) do
    client(base_url, api_key)
    |> Req.post(url: "/api/v1/workflows/#{workflow_id}/activate")
    |> handle_response()
  end

  defp client(base_url, api_key) do
    Req.new(base_url: base_url, headers: [{"X-N8N-API-KEY", api_key}])
  end

  defp handle_response({:ok, %{status: status, body: body}}) when status in 200..299 do
    {:ok, body}
  end

  defp handle_response({:ok, %{status: status, body: body}}) do
    {:error, %{status: status, body: body}}
  end

  defp handle_response({:error, reason}) do
    {:error, reason}
  end
end
