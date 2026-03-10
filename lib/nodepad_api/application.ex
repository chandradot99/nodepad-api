defmodule NodepadApi.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      NodepadApiWeb.Telemetry,
      NodepadApi.Repo,
      {DNSCluster, query: Application.get_env(:nodepad_api, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: NodepadApi.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: NodepadApi.Finch},
      # Start a worker by calling: NodepadApi.Worker.start_link(arg)
      # {NodepadApi.Worker, arg},
      # Start to serve requests, typically the last entry
      NodepadApiWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: NodepadApi.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    NodepadApiWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
