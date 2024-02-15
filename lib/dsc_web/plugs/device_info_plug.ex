defmodule DriversSeatCoopWeb.DeviceInfoPlug do
  @moduledoc """
  This plug captures headers sent from the mobile device on each request
  """
  import Plug.Conn

  def init(_), do: []

  def call(conn, _opts) do
    device = extract_and_save_device_info(conn)

    if is_nil(device) do
      conn
    else
      assign(conn, :dsc_device, device)
    end
  end

  def extract_and_save_device_info(conn) do
    user = Map.get(conn.assigns, :user)

    device_info = extract_device_info(conn)

    save_device_info(
      user,
      Map.get(device_info, :device_id),
      Map.get(device_info, :device_app_version),
      Map.get(device_info, :device_os),
      Map.get(device_info, :device_lang),
      Map.get(device_info, :device_platform),
      Map.get(device_info, :device_name),
      Map.get(device_info, :location_tracking_config_status)
    )
  end

  def extract_device_info(conn) do
    %{
      device_id: get_header_value_from_request(conn, :dsc_device_id),
      device_app_version: get_header_value_from_request(conn, :dsc_app_version),
      device_os: get_header_value_from_request(conn, :dsc_device_os),
      device_lang: get_header_value_from_request(conn, :dsc_device_language),
      device_platform: get_header_value_from_request(conn, :dsc_device_platform),
      device_name: get_header_value_from_request(conn, :dsc_device_name),
      location_tracking_config_status:
        get_header_value_from_request(conn, :dsc_location_tracking_config_status)
    }
  end

  defp save_device_info(
         nil,
         _device_id,
         _device_app_version,
         _device_os,
         _device_lang,
         _device_platform,
         _device_name,
         _location_tracking_config_status
       ) do
    nil
  end

  defp save_device_info(
         _user,
         nil,
         _device_app_version,
         _device_os,
         _device_lang,
         _device_platform,
         _device_name,
         _location_tracking_config_status
       ) do
    nil
  end

  defp save_device_info(
         user,
         device_id,
         device_app_version,
         device_os,
         device_lang,
         device_platform,
         device_name,
         location_tracking_config_status
       ) do
    attrs = %{}

    attrs =
      if is_nil(device_app_version) do
        attrs
      else
        Map.put(attrs, :app_version, device_app_version)
      end

    attrs =
      if is_nil(device_os) do
        attrs
      else
        Map.put(attrs, :device_os, device_os)
      end

    attrs =
      if is_nil(device_lang) do
        attrs
      else
        Map.put(attrs, :device_language, device_lang)
      end

    attrs =
      if is_nil(device_platform) do
        attrs
      else
        Map.put(attrs, :device_platform, device_platform)
      end

    attrs =
      case device_name do
        val when val in [nil, "undefined"] ->
          attrs

        _ ->
          Map.put(attrs, :device_name, device_name)
      end

    attrs =
      if is_nil(location_tracking_config_status) or location_tracking_config_status == "" do
        attrs
      else
        Map.put(attrs, :location_tracking_config_status, location_tracking_config_status)
      end

    DriversSeatCoop.Devices.get_or_update!(user.id, device_id, attrs)
  end

  defp get_header_value_from_request(conn, key) when is_atom(key) do
    header_key =
      key
      |> Atom.to_string()
      |> String.replace("_", "-")

    conn
    |> get_req_header(header_key)
    |> get_header_value(key)
  end

  defp get_header_value(values, key)
       when is_atom(key) and is_list(values) do
    get_header_value(List.first(values), key)
  end

  defp get_header_value(nil, key) when is_atom(key) do
    nil
  end

  defp get_header_value(value, key)
       when is_atom(key) do
    value = String.trim(value)

    if String.length(value) == 0 do
      nil
    else
      String.downcase(value)
    end
  end
end
