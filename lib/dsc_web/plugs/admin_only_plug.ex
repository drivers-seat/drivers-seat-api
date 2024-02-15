defmodule DriversSeatCoopWeb.AdminOnlyPlug do
  @behaviour Plug
  import Plug.Conn, only: [halt: 1, put_status: 2]

  alias DriversSeatCoop.Accounts

  def init(_opts) do
    []
  end

  def call(conn, _) do
    user = conn.assigns[:user]

    if Accounts.is_admin?(user) do
      conn
    else
      conn
      |> put_status(404)
      |> Phoenix.Controller.put_view(DriversSeatCoopWeb.ErrorView)
      |> Phoenix.Controller.render("404.json")
      |> halt()
    end
  end
end
