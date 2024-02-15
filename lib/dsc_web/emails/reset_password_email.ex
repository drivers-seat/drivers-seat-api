defmodule DriversSeatCoopWeb.ResetPasswordEmail do
  use Phoenix.Swoosh,
    view: DriversSeatCoopWeb.EmailView,
    layout: {DriversSeatCoopWeb.LayoutView, :email}

  alias DriversSeatCoop.Accounts.User

  def reset_password(user) do
    new()
    |> to({User.name(user), user.email})
    |> from(
      {DriversSeatCoopWeb.Mailer.from_email_name(),
       DriversSeatCoopWeb.Mailer.from_email_address()}
    )
    |> subject("Forgot Password")
    |> render_body("forgot_password.html", %{user: user})
  end
end
