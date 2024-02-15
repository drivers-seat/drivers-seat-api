defmodule DriversSeatCoopWeb.ResetPasswordView do
  use DriversSeatCoopWeb, :view

  def render("show.json", _) do
    %{
      data: %{
        success: true
      }
    }
  end
end
