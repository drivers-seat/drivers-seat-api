defmodule DriversSeatCoopWeb.NewHelpRequestEmail do
  use Phoenix.Swoosh,
    view: DriversSeatCoopWeb.EmailView,
    layout: {DriversSeatCoopWeb.LayoutView, :email}

  def new_help_request(recipients, subject, description, from_user \\ nil, from_device \\ nil) do
    model =
      %{
        subject: subject,
        description: description
      }
      |> Map.merge(from_device || %{})
      |> Map.merge(from_user || %{})

    email_subject =
      if is_nil(subject),
        do: "New Help Request",
        else: "New Help Request - #{subject}"

    new()
    |> to(recipients)
    |> from(
      {DriversSeatCoopWeb.Mailer.from_email_name(),
       DriversSeatCoopWeb.Mailer.from_email_address()}
    )
    |> subject(email_subject)
    |> render_body("new_help_request.html", model)
  end
end
