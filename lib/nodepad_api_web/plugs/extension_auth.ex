defmodule NodepadApiWeb.Plugs.ExtensionAuth do
  import Plug.Conn
  alias NodepadApi.Accounts

  def init(opts), do: opts

  def call(conn, _opts) do
    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
         user when not is_nil(user) <- Accounts.get_user_by_extension_token(token) do
      assign(conn, :current_user, user)
    else
      _ ->
        conn
        |> put_status(:unauthorized)
        |> Phoenix.Controller.json(%{error: "Invalid or missing extension token"})
        |> halt()
    end
  end
end
