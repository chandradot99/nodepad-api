defmodule NodepadApi.Auth.Pipeline do
  use Guardian.Plug.Pipeline,
    otp_app: :nodepad_api,
    module: NodepadApi.Auth.Guardian,
    error_handler: NodepadApi.Auth.ErrorHandler

  plug Guardian.Plug.VerifyHeader, scheme: "Bearer"
  plug Guardian.Plug.EnsureAuthenticated
  plug Guardian.Plug.LoadResource
end
