defmodule DriversSeatCoop.Help do
  require Logger

  def submit_help_request(subject, description, name, email, user \\ nil, device \\ nil) do
    recipients = forward_to()

    user = user || %{}

    user_info = %{
      user_id: Map.get(user, :id),
      email_address: email || Map.get(user, :email),
      name: name || "#{Map.get(user, :first_name)} #{Map.get(user, :last_name)}"
    }

    device = device || %{}

    device_info = %{
      device_id: Map.get(device, :device_id),
      app_version: Map.get(device, :app_version),
      device_platform: Map.get(device, :device_platform),
      device_os: Map.get(device, :device_os),
      location_tracking_config_status: Map.get(device, :location_tracking_config_status)
    }

    log_map = %{
      subject: subject,
      description: description,
      user: user_info,
      device: device_info
    }

    if Enum.any?(recipients) do
      Logger.info(Map.put(log_map, :title, "New Help Request submitted"))

      email =
        DriversSeatCoopWeb.NewHelpRequestEmail.new_help_request(
          recipients,
          subject,
          description,
          user_info,
          device_info
        )

      {DriversSeatCoopWeb.Mailer.deliver(email), email}
    else
      Logger.warn(Map.put(log_map, :problem, "New Help Request, no recipients configured"))
    end
  end

  defp get_config do
    Application.get_env(:dsc, DriversSeatCoop.Help)
  end

  defp forward_to do
    config = get_config()

    if is_nil(config) or is_nil(Keyword.get(config, :forward_to_csv)),
      do: [],
      else: String.split(Keyword.get(config, :forward_to_csv), ",", trim: true)
  end
end
