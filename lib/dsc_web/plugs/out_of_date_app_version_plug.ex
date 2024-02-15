defmodule DriversSeatCoopWeb.OutOfDateAppVersionPlug do
  @moduledoc """
  This plug will check for outdated versions of the app.  It will 
  return HTTP status code 405 with information about how to upgrade
  """
  import Plug.Conn

  alias DriversSeatCoop.Devices.Device
  alias DriversSeatCoopWeb.DeviceInfoPlug

  def init(_), do: []

  def call(conn, _opts) do
    device_info = DeviceInfoPlug.extract_device_info(conn)
    min_version = get_min_app_version()

    handle_device_info(conn, device_info, min_version)
  end

  defp handle_device_info(conn, nil = _device_info, _min_app_version), do: conn

  defp handle_device_info(conn, _device_info, nil = _min_app_version), do: conn

  defp handle_device_info(conn, %{} = device_info, min_version) do
    app_version = Map.get(device_info, :device_app_version)
    device_platform = Map.get(device_info, :device_platform)
    version_requirement = ">= #{min_version}"

    cond do
      # If not supplied on the API call, don't enforce the requirement
      is_nil(app_version) and is_nil(device_platform) ->
        conn

      # Meets the requirement
      Device.is_version_match?(app_version, version_requirement) ->
        conn

      # Does not meet the requirement
      true ->
        store_url =
          case device_platform do
            "ios" -> get_store_url_ios()
            "android" -> get_store_url_android()
            _ -> get_store_url_other()
          end || get_store_url_other()

        info = %{
          calling_os: device_platform,
          calling_version: app_version,
          minimum_version: min_version,
          store_url: store_url,
          title: "App version #{app_version} is no longer supported",
          message: "Install the latest version to keep up to date on new features and bug fixes."
        }

        conn
        |> put_status(:upgrade_required)
        |> Phoenix.Controller.put_view(DriversSeatCoopWeb.ErrorView)
        |> Phoenix.Controller.render("426.json", %{info: info})
        |> halt()
    end
  end

  defp get_config do
    Application.get_env(:dsc, DriversSeatCoopWeb.OutOfDateAppVersionPlug)
  end

  def get_min_app_version, do: get_min_app_version(get_config())

  defp get_min_app_version(nil = _config), do: nil

  defp get_min_app_version(config) do
    Keyword.get(config, :min_version)
  end

  def get_store_url_ios, do: get_store_url_ios(get_config())

  defp get_store_url_ios(nil = _config), do: nil

  defp get_store_url_ios(config) do
    Keyword.get(config, :store_url_ios)
  end

  def get_store_url_android, do: get_store_url_android(get_config())

  defp get_store_url_android(nil = _config), do: nil

  defp get_store_url_android(config) do
    Keyword.get(config, :store_url_android)
  end

  def get_store_url_other, do: get_store_url_other(get_config())

  defp get_store_url_other(nil = _config), do: nil

  defp get_store_url_other(config) do
    Keyword.get(config, :store_url_default)
  end
end
