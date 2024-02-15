defmodule DriversSeatCoopWeb.AppDowntimePlug do
  alias DriversSeatCoop.Accounts

  @default_message "Driver's Seat is currently undergoing maintenance.  Sorry for the inconvenience, we'll be back shortly."
  @default_title "Driver's Seat Maintenance"

  @moduledoc """
  This plug will check configuration to see if the app should be in a downtime.
  If the app should be in downtime, it further checks to see if we are allowing
  Admin users access to the app for testing purposes, etc.

  We do this instead of Heroku maintenance mode b/c Heroku Maintenance mode does
  not place and CORS headers in their reponse (making it not usable by the ionic App)

  """
  import Plug.Conn

  @doc """
  This plug may be used 
  """
  def init(requires_authentication), do: requires_authentication

  def call(conn, requires_authentication) do
    config = get_config()

    cond do
      # it is not a downtime
      not is_downtime?(config) ->
        conn

      # it is a downtime, but allows admins
      # plug configured to not require authenticated user
      is_admin_only?(config) and not requires_authentication ->
        conn

      # it is a downtime, but allows admins
      # and the authenticated user is an admin
      is_admin_only?(config) and Accounts.is_admin?(Map.get(conn.assigns, :user)) ->
        conn

      # otherwise, return downtime response
      true ->
        send_downtime_response(conn, config)
    end
  end

  defp send_downtime_response(conn, config) do
    info = %{
      title: Keyword.get(config, :downtime_title) || @default_title,
      message: Keyword.get(config, :downtime_message) || @default_message,
      admin_only: is_admin_only?(config)
    }

    conn
    |> put_status(503)
    |> Phoenix.Controller.put_view(DriversSeatCoopWeb.ErrorView)
    |> Phoenix.Controller.render("503.json", %{info: info})
    |> halt()
  end

  defp get_config do
    Application.get_env(:dsc, DriversSeatCoopWeb.AppDowntimePlug)
  end

  defp is_downtime?(nil = _config), do: false

  defp is_downtime?(config) do
    Keyword.get(config, :is_downtime?, false)
  end

  defp is_admin_only?(nil = _config), do: false

  defp is_admin_only?(config) do
    Keyword.get(config, :allow_admins?, false)
  end
end
