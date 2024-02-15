defmodule DriversSeatCoopWeb.ResetPasswordController do
  use DriversSeatCoopWeb, :controller

  alias DriversSeatCoop.Accounts
  alias DriversSeatCoop.Accounts.User
  action_fallback DriversSeatCoopWeb.FallbackController

  def create(conn, %{"reset_password" => reset_password_params}) do
    with {:ok, params} <- DriversSeatCoopWeb.ResetPasswordValidator.create(reset_password_params),
         user = %User{} <- Accounts.get_user_by_email(params.email),
         {:ok, user} <- Accounts.reset_password_user(user) do
      Accounts.create_reset_password_user_action(user)
      Accounts.send_reset_password_email(user)
    end

    conn
    |> render("show.json", %{})
  end
end
