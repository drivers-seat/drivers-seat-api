defmodule DriversSeatCoopWeb.Web.ResetPasswordController do
  use DriversSeatCoopWeb, :controller

  alias DriversSeatCoop.Accounts

  def edit(conn, %{"id" => reset_token}) do
    user = Accounts.get_user_by_reset_password_token!(reset_token)
    changeset = Accounts.change_user_password(user)
    render(conn, "edit.html", user: user, changeset: changeset)
  end

  def update(conn, %{"id" => reset_token, "user" => user_params}) do
    user = Accounts.get_user_by_reset_password_token!(reset_token)

    case Accounts.update_user_password(user, user_params) do
      {:ok, _user} ->
        render(conn, "success.html")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", user: user, changeset: changeset)
    end
  end
end
