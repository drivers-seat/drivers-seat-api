defmodule DriversSeatCoopWeb.HelpController do
  use DriversSeatCoopWeb, :controller

  alias DriversSeatCoop.Help
  alias DriversSeatCoopWeb.DeviceInfoPlug

  action_fallback DriversSeatCoopWeb.FallbackController

  def create(conn, params) do
    with {:ok, help_request} <- DriversSeatCoopWeb.HelpRequestValidator.create(params) do
      user = Map.get(conn.assigns, :user)
      device = Map.get(conn.assigns, :dsc_device) || DeviceInfoPlug.extract_device_info(conn)

      Help.submit_help_request(
        Map.get(help_request, :subject),
        Map.get(help_request, :message),
        Map.get(help_request, :name),
        Map.get(help_request, :email),
        user,
        device
      )

      send_resp(conn, :no_content, "")
    end
  end
end
