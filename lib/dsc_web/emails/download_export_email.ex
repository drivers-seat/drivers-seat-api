defmodule DriversSeatCoopWeb.DownloadExportEmail do
  use Phoenix.Swoosh,
    view: DriversSeatCoopWeb.EmailView,
    layout: {DriversSeatCoopWeb.LayoutView, :email}

  require Logger

  def download_export(download_url, description, recipients, copy_recipients) do
    new()
    |> to(recipients)
    |> from(
      {DriversSeatCoopWeb.Mailer.from_email_name(),
       DriversSeatCoopWeb.Mailer.from_email_address()}
    )
    |> bcc(copy_recipients)
    |> subject(description)
    |> render_body("download_export.html", %{
      download_url: download_url
    })
  end
end
