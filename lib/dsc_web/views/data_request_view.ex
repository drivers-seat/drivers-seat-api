defmodule DriversSeatCoopWeb.DataRequestView do
  use DriversSeatCoopWeb, :view

  def render("show.json", _) do
    %{
      data: %{
        success: true
      }
    }
  end
end
