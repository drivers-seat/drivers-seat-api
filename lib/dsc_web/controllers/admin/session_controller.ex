defmodule DriversSeatCoopWeb.Admin.SessionController do
  use DriversSeatCoopWeb, :controller

  alias DriversSeatCoop.Accounts
  alias DriversSeatCoop.Accounts.User

  def new(conn, _params) do
    render(conn, "new.html", email: "")
  end

  def create(conn, %{"email" => email, "password" => password}) do
    case Accounts.get_admin_by_email_and_password(email, password) do
      {:ok, %User{} = user} ->
        conn
        |> put_session(:user_id, user.id)
        |> put_flash(:info, "Logged in successfully.")
        |> redirect(to: Routes.admin_page_path(conn, :index))

      _ ->
        conn
        |> put_flash(:error, "Email or password is incorrect")
        |> render("new.html", email: email)
    end
  end

  def logout(conn, _params) do
    conn
    |> delete_session(:user_id)
    |> put_flash(:info, "Logged out successfully")
    |> redirect(to: Routes.admin_session_path(conn, :new))
  end
end
