defmodule DriversSeatCoopWeb.Admin.PageController do
  use DriversSeatCoopWeb, :controller

  plug DriversSeatCoopWeb.AdminAuthenticationPlug

  def index(conn, _params) do
    redirect(conn, to: Routes.admin_user_path(conn, :index))
  end
end
