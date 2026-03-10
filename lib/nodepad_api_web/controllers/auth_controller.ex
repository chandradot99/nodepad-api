defmodule NodepadApiWeb.AuthController do
  use NodepadApiWeb, :controller

  alias NodepadApi.Accounts
  alias NodepadApi.Auth.Guardian

  def register(conn, params) do
    case Accounts.create_user(params) do
      {:ok, user} ->
        {:ok, token, _claims} = Guardian.encode_and_sign(user)
        json(conn, %{token: token, user: %{id: user.id, email: user.email, name: user.name}})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: format_errors(changeset)})
    end
  end

  def login(conn, %{"email" => email, "password" => password}) do
    case Accounts.authenticate_user(email, password) do
      {:ok, user} ->
        {:ok, token, _claims} = Guardian.encode_and_sign(user)
        json(conn, %{token: token, user: %{id: user.id, email: user.email, name: user.name}})

      {:error, _reason} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Invalid email or password"})
    end
  end

  def me(conn, _params) do
    user = Guardian.Plug.current_resource(conn)
    json(conn, %{id: user.id, email: user.email, name: user.name})
  end

  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
