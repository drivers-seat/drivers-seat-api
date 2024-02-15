defmodule DriversSeatCoopWeb.AdminAuthenticationPlug do
  @behaviour Plug
  import Plug.Conn, only: [assign: 3, get_session: 2, halt: 1]

  alias DriversSeatCoop.Accounts
  alias DriversSeatCoop.Accounts.User
  alias DriversSeatCoopWeb.Router

  def init(_opts) do
  end

  def call(conn, _opts) do
    with user_id when not is_nil(user_id) <- get_session(conn, :user_id),
         %User{} = user <- Accounts.get_user(user_id),
         true <- Accounts.is_admin?(user) do
      assign(conn, :user, user)
    else
      _ ->
        Phoenix.Controller.redirect(
          conn,
          to:
            Router.Helpers.admin_session_path(
              DriversSeatCoopWeb.Endpoint,
              :new
            )
        )
        |> halt()
    end
  end
end
