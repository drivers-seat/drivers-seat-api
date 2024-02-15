defmodule DriversSeatCoopWeb.DataRequestController do
  use DriversSeatCoopWeb, :controller

  alias DriversSeatCoop.Export.UserRequest

  plug DriversSeatCoopWeb.AuthenticationPlug
  action_fallback DriversSeatCoopWeb.FallbackController

  def create(conn, _params) do
    user_id = conn.assigns.user.id

    UserRequest.export_all(user_id)

    conn
    |> render("show.json", %{})
  end
end
