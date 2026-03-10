defmodule NodepadApiWeb.Router do
  use NodepadApiWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :auth do
    plug NodepadApi.Auth.Pipeline
  end

  # Public routes
  scope "/api", NodepadApiWeb do
    pipe_through :api

    post "/auth/register", AuthController, :register
    post "/auth/login", AuthController, :login
  end

  # Protected routes
  scope "/api", NodepadApiWeb do
    pipe_through [:api, :auth]

    get "/auth/me", AuthController, :me

    # Workspaces
    get "/workspaces", WorkspaceController, :index
    post "/workspaces", WorkspaceController, :create
    delete "/workspaces/:id", WorkspaceController, :delete

    # Connections (n8n instances)
    get "/workspaces/:workspace_id/connections", ConnectionController, :index
    post "/workspaces/:workspace_id/connections", ConnectionController, :create
    get "/connections/:id/test", ConnectionController, :test
    delete "/connections/:id", ConnectionController, :delete

    # Workflows
    get "/connections/:connection_id/workflows", WorkflowController, :index
    get "/workflows/:id", WorkflowController, :show
    post "/workflows/:id/push", WorkflowController, :push

    # Drafts
    get "/workflows/:workflow_id/drafts", DraftController, :index
    post "/workflows/:workflow_id/drafts", DraftController, :create
    post "/drafts/:id/push", DraftController, :push
    delete "/drafts/:id", DraftController, :delete

    # Chat
    get "/workflows/:workflow_id/conversations", ChatController, :list_conversations
    post "/workflows/:workflow_id/conversations", ChatController, :create_conversation
    post "/conversations/:conversation_id/messages", ChatController, :send_message
  end

  if Application.compile_env(:nodepad_api, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]
      live_dashboard "/dashboard", metrics: NodepadApiWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
