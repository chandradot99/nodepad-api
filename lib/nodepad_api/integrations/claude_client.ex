defmodule NodepadApi.Integrations.ClaudeClient do
  @moduledoc "HTTP client for Anthropic Claude API"

  @api_url "https://api.anthropic.com"
  @model "claude-sonnet-4-6"
  @max_tokens 8192

  def chat(api_key, messages, system_prompt \\ nil) do
    body =
      %{model: @model, max_tokens: @max_tokens, messages: messages}
      |> maybe_add_system(system_prompt)

    Req.new(base_url: @api_url)
    |> Req.post(
      url: "/v1/messages",
      headers: [
        {"x-api-key", api_key},
        {"anthropic-version", "2023-06-01"}
      ],
      json: body
    )
    |> handle_response()
  end

  defp maybe_add_system(body, nil), do: body
  defp maybe_add_system(body, system), do: Map.put(body, :system, system)

  defp handle_response({:ok, %{status: 200, body: body}}) do
    content = get_in(body, ["content", Access.at(0), "text"])
    {:ok, content}
  end

  defp handle_response({:ok, %{status: status, body: body}}) do
    {:error, %{status: status, body: body}}
  end

  defp handle_response({:error, reason}) do
    {:error, reason}
  end
end
