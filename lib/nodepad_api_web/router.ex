defmodule NodepadApiWeb.Router do
  use NodepadApiWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :auth do
    plug NodepadApi.Auth.Pipeline
  end

  pipeline :extension_auth do
    plug NodepadApiWeb.Plugs.ExtensionAuth
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
    patch "/workspaces/:id", WorkspaceController, :update
    delete "/workspaces/:id", WorkspaceController, :delete

    # Connections (n8n instances)
    get "/workspaces/:workspace_id/connections", ConnectionController, :index
    post "/workspaces/:workspace_id/connections", ConnectionController, :create
    patch "/connections/:id", ConnectionController, :update
    get "/connections/:id/test", ConnectionController, :test
    get "/connections/:id/credentials", ConnectionController, :credentials
    get "/connections/:id/saved-credentials", ConnectionController, :saved_credentials
    get "/connections/:id/nodes", ConnectionController, :nodes
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

    # Extension token management
    get "/extension-token/status", ExtensionController, :token_status
    post "/extension-token", ExtensionController, :generate_token
    delete "/extension-token", ExtensionController, :revoke_token

    # Chat
    get "/workflows/:workflow_id/conversations", ChatController, :list_conversations
    post "/workflows/:workflow_id/conversations", ChatController, :create_conversation
    get "/conversations/:conversation_id/messages", ChatController, :list_messages
    post "/conversations/:conversation_id/messages", ChatController, :send_message
  end

  # Extension sync (uses extension token, not JWT)
  scope "/api", NodepadApiWeb do
    pipe_through [:api, :extension_auth]

    post "/sync/nodes", ExtensionController, :sync_nodes
    post "/sync/credential-types", ExtensionController, :sync_credential_types
    post "/sync/saved-credentials", ExtensionController, :sync_saved_credentials
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
