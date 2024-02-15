defmodule DriversSeatCoopWeb.AppContentController do
  use DriversSeatCoopWeb, :controller

  plug(:put_root_layout, false)
  plug(:put_layout, {DriversSeatCoopWeb.LayoutView, "app_content.html"})

  require Logger

  def campaign_styles(conn, params) do
    render(conn, "campaign_styles.scss", params)
  end

  def onboarding_status(conn, _params) do
    render(conn, "onboarding_status.html", %{
      items: [
        {"Connect Accounts", "window.appFunctions.showAlert('JayDizzle')", :completed},
        {"Set a Goal", "window.appFunctions.logConsole('JayDizzle')", :warning},
        {"weeee", "window.appFunctions.showAlert('JayDizzle')", :error},
        {"wonk wonk ", nil, :error}
      ]
    })
  end
end
