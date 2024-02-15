defmodule DriversSeatCoopWeb.DownloadEarningsEmail do
  use Phoenix.Swoosh,
    view: DriversSeatCoopWeb.EmailView,
    layout: {DriversSeatCoopWeb.LayoutView, :email}

  alias DriversSeatCoop.Accounts.User

  def download_earnings(user, download_url, date_start, date_end) do
    new()
    |> to({User.name(user), user.email})
    |> from(
      {DriversSeatCoopWeb.Mailer.from_email_name(),
       DriversSeatCoopWeb.Mailer.from_email_address()}
    )
    |> subject("Your Earnings and Mileage Export Is Ready!")
    |> render_body("download_earnings.html", %{
      user: user,
      download_url: download_url,
      date_start: date_start,
      date_end: date_end
    })
  end
end
