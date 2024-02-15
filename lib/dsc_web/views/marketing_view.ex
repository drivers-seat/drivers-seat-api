defmodule DriversSeatCoopWeb.MarketingView do
  use DriversSeatCoopWeb, :view

  def render("index.json", %{
        campaigns: campaigns
      }) do
    %{
      data: campaigns
    }
  end
end
