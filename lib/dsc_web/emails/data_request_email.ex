defmodule DriversSeatCoopWeb.DataRequestEmail do
  use Phoenix.Swoosh,
    view: DriversSeatCoopWeb.EmailView,
    layout: {DriversSeatCoopWeb.LayoutView, :email}

  alias DriversSeatCoop.Accounts.User

  def data_request(user) do
    new()
    |> to({User.name(user), user.email})
    |> from({"Request personal data", "privacy@driversseat.co"})
    |> subject("User request personal data")
    |> render_body("data_request.html", %{user: user})
  end
end
