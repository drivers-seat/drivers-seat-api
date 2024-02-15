defmodule DriversSeatCoopWeb.SessionController do
  use DriversSeatCoopWeb, :controller

  alias DriversSeatCoop.Accounts
  alias DriversSeatCoop.Legal
  alias DriversSeatCoop.Shifts
  alias DriversSeatCoopWeb.SessionValidator

  plug DriversSeatCoopWeb.AuthenticationPlug when action in [:index]

  action_fallback DriversSeatCoopWeb.FallbackController

  def index(conn, _params) do
    token = Accounts.token_for_user_id(conn.assigns.user.id)
    Accounts.create_session_refresh_user_action(conn.assigns.user)
    user = put_current_shift(conn.assigns.user, Map.get(conn.assigns, :dsc_device))
    user = put_user_agreed_to_current_terms(user)

    conn
    |> DriversSeatCoopWeb.AuthenticationPlug.put_auth_header(token)
    |> put_view(DriversSeatCoopWeb.UserView)
    |> render("show.json", user: user)
  end

  def create(conn, %{"session" => session_params}) do
    with {:ok, params} <- SessionValidator.create(session_params),
         {:ok, user} <-
           Accounts.get_user_by_email_and_password(
             params.email,
             params.password
           ) do
      Accounts.create_login_user_action(user)
      token = Accounts.token_for_user_id(user.id)

      conn =
        conn
        |> DriversSeatCoopWeb.AuthenticationPlug.put_auth_header(token)
        |> DriversSeatCoopWeb.AuthenticationPlug.put_user(user)
        |> DriversSeatCoopWeb.DeviceInfoPlug.call(nil)

      user = put_current_shift(user, Map.get(conn.assigns, :dsc_device))
      user = put_user_agreed_to_current_terms(user)

      conn
      |> put_view(DriversSeatCoopWeb.UserView)
      |> render("show.json", user: user)
    end
  end

  def ghost_admin_user(conn, %{"user_id" => user_id}) do
    with ghost_user <- Accounts.get_user!(user_id) do
      Accounts.create_ghost_user_login_action(conn.assigns.user, ghost_user)
      token = Accounts.token_for_user_id(ghost_user.id)
      # ghost users can never be on-shift
      ghost_user = Map.put(ghost_user, :currently_on_shift, nil)

      conn
      |> DriversSeatCoopWeb.AuthenticationPlug.put_auth_header(token)
      |> put_view(DriversSeatCoopWeb.UserView)
      |> render("show.json", user: ghost_user)
    end
  end

  defp put_current_shift(user, nil) do
    user |> Map.put(:currently_on_shift, Shifts.get_current_shift_id(user.id, nil))
  end

  defp put_current_shift(user, device) do
    user |> Map.put(:currently_on_shift, Shifts.get_current_shift_id(user.id, device.id))
  end

  defp put_user_agreed_to_current_terms(user) do
    terms_current =
      case Legal.user_has_agreed_to_latest_terms_by(user, NaiveDateTime.utc_now()) do
        :ok ->
          true

        {:error, _} ->
          false
      end

    Map.put(user, :agreed_to_current_terms, terms_current)
  end
end
