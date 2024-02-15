defmodule DriversSeatCoopWeb.MetroAreaController do
  use DriversSeatCoopWeb, :controller
  alias DriversSeatCoop.Regions

  def index(conn, _params) do
    metro_areas = Regions.get_metro_areas()
    render(conn, "index.json", metro_areas: metro_areas)
  end
end
