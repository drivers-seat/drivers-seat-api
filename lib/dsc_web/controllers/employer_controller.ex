defmodule DriversSeatCoopWeb.EmployerController do
  use DriversSeatCoopWeb, :controller
  alias DriversSeatCoop.Employers

  def index(conn, _params) do
    employers = Employers.list_employer_service_classes()
    render(conn, "index.json", employers: employers)
  end
end
