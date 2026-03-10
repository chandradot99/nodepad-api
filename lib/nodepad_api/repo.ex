defmodule NodepadApi.Repo do
  use Ecto.Repo,
    otp_app: :nodepad_api,
    adapter: Ecto.Adapters.Postgres
end
