defmodule DriversSeatCoopWeb.DeviceInfoPlugTest do
  use DriversSeatCoopWeb.ConnCase, async: true

  alias DriversSeatCoopWeb.AuthenticationPlug
  alias DriversSeatCoopWeb.DeviceInfoPlug

  @device_id_key "dsc-device-id"
  @app_version_key "dsc-app-version"
  @os_key "dsc-device-os"
  @language_key "dsc-device-language"
  @device_name_key "dsc-device-name"
  @platform_key "dsc-device-platform"
  @location_config_key "dsc-location-tracking-config-status"

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "call" do
    test "adds extracted values to conn", %{conn: conn} do
      user = Factory.create_user()

      conn =
        conn
        |> TestHelpers.put_auth_header(user)
        |> AuthenticationPlug.call([])
        |> put_req_header(@device_id_key, "device")
        |> put_req_header(@app_version_key, "version")
        |> put_req_header(@os_key, "os")
        |> put_req_header(@language_key, "lang")
        |> put_req_header(@device_name_key, "name")
        |> put_req_header(@platform_key, "platform")
        |> put_req_header(@location_config_key, "location")
        |> DeviceInfoPlug.call(nil)

      device = Map.get(conn.assigns, :dsc_device)

      assert not is_nil(device)
      assert device.app_version == "version"
      assert device.device_id == "device"
      assert device.device_os == "os"
      assert device.device_language == "lang"
      assert device.device_platform == "platform"
      assert device.device_name == "name"
      assert device.location_tracking_config_status == "location"
    end

    test "lower cases values", %{conn: conn} do
      user = Factory.create_user()

      conn =
        conn
        |> TestHelpers.put_auth_header(user)
        |> AuthenticationPlug.call([])
        |> put_req_header(@device_id_key, "Device")
        |> put_req_header(@app_version_key, "VERSION")
        |> put_req_header(@os_key, "os")
        |> put_req_header(@language_key, "lang")
        |> put_req_header(@device_name_key, "NAME")
        |> put_req_header(@platform_key, "PlAtForm")
        |> put_req_header(@location_config_key, "lOcAtIon")
        |> DeviceInfoPlug.call(nil)

      device = Map.get(conn.assigns, :dsc_device)

      assert not is_nil(device)
      assert device.app_version == "version"
      assert device.device_id == "device"
      assert device.device_os == "os"
      assert device.device_language == "lang"
      assert device.device_platform == "platform"
      assert device.device_name == "name"
      assert device.location_tracking_config_status == "location"
    end

    test "trims values", %{conn: conn} do
      user = Factory.create_user()

      conn =
        conn
        |> TestHelpers.put_auth_header(user)
        |> AuthenticationPlug.call([])
        |> put_req_header(@device_id_key, "    Device   ")
        |> put_req_header(@app_version_key, "version   ")
        |> put_req_header(@os_key, "\r\nos ")
        |> put_req_header(@language_key, "\tlang")
        |> put_req_header(@device_name_key, "   name   ")
        |> put_req_header(@platform_key, "  platform")
        |> put_req_header(@location_config_key, "   location ")
        |> DeviceInfoPlug.call(nil)

      device = Map.get(conn.assigns, :dsc_device)

      assert not is_nil(device)
      assert device.app_version == "version"
      assert device.device_id == "device"
      assert device.device_os == "os"
      assert device.device_language == "lang"
      assert device.device_platform == "platform"
      assert device.device_name == "name"
      assert device.location_tracking_config_status == "location"
    end

    test "does not capture empty string value", %{conn: conn} do
      user = Factory.create_user()

      conn =
        conn
        |> TestHelpers.put_auth_header(user)
        |> AuthenticationPlug.call([])
        |> put_req_header(@device_id_key, "     ")
        |> put_req_header(@app_version_key, "")
        |> put_req_header(@os_key, "\r\n")
        |> put_req_header(@language_key, "\t")
        |> put_req_header(@language_key, "\t")
        |> put_req_header(@device_name_key, " ")
        |> put_req_header(@platform_key, "\t ")
        |> put_req_header(@location_config_key, " ")
        |> DeviceInfoPlug.call(nil)

      device = Map.get(conn.assigns, :dsc_device)
      assert is_nil(device)
    end

    test "does not capture undefined as device name", %{conn: conn} do
      user = Factory.create_user()

      conn =
        conn
        |> TestHelpers.put_auth_header(user)
        |> AuthenticationPlug.call([])
        |> put_req_header(@device_id_key, "device")
        |> put_req_header(@app_version_key, "version")
        |> put_req_header(@os_key, "os")
        |> put_req_header(@language_key, "lang")
        |> put_req_header(@device_name_key, "undefined")
        |> put_req_header(@platform_key, "platform")
        |> DeviceInfoPlug.call(nil)

      device = Map.get(conn.assigns, :dsc_device)

      assert not is_nil(device)
      assert device.app_version == "version"
      assert device.device_id == "device"
      assert device.device_os == "os"
      assert device.device_language == "lang"
      assert device.device_platform == "platform"
      assert is_nil(device.device_name)
    end

    test "does not return error when value is missing", %{conn: conn} do
      conn =
        conn
        |> DeviceInfoPlug.call(nil)

      assert(conn)
    end

    test "does not add device without user", %{conn: conn} do
      conn =
        conn
        |> put_req_header(@device_id_key, "device")
        |> put_req_header(@app_version_key, "version")
        |> put_req_header(@os_key, "os")
        |> put_req_header(@language_key, "lang")
        |> DeviceInfoPlug.call(nil)

      device = Map.get(conn.assigns, :dsc_device)

      assert is_nil(device)
    end

    test "does not add device without device_id", %{conn: conn} do
      user = Factory.create_user()

      conn =
        conn
        |> TestHelpers.put_auth_header(user)
        |> AuthenticationPlug.call([])
        |> put_req_header(@app_version_key, "version")
        |> put_req_header(@os_key, "os")
        |> put_req_header(@language_key, "lang")
        |> DeviceInfoPlug.call(nil)

      device = Map.get(conn.assigns, :dsc_device)

      assert is_nil(device)
    end

    test "does not fail if only user and device are available", %{conn: conn} do
      user = Factory.create_user()

      conn =
        conn
        |> TestHelpers.put_auth_header(user)
        |> AuthenticationPlug.call([])
        |> put_req_header(@device_id_key, "device")
        |> DeviceInfoPlug.call(nil)

      device = Map.get(conn.assigns, :dsc_device)

      assert not is_nil(device)
    end

    test "does not clear out old values if not supplied on current call", %{conn: conn} do
      user = Factory.create_user()

      conn1 =
        conn
        |> TestHelpers.put_auth_header(user)
        |> AuthenticationPlug.call([])
        |> put_req_header(@device_id_key, "device")
        |> put_req_header(@app_version_key, "version")
        |> put_req_header(@os_key, "os")
        |> put_req_header(@language_key, "lang")
        |> DeviceInfoPlug.call(nil)

      device1 = Map.get(conn1.assigns, :dsc_device)

      conn2 =
        conn
        |> TestHelpers.put_auth_header(user)
        |> AuthenticationPlug.call([])
        |> put_req_header(@device_id_key, "device")
        |> DeviceInfoPlug.call(nil)

      device2 = Map.get(conn2.assigns, :dsc_device)

      assert device1 == device2
    end

    test "does update existing values when supplied on current call", %{conn: conn} do
      user = Factory.create_user()

      conn1 =
        conn
        |> TestHelpers.put_auth_header(user)
        |> AuthenticationPlug.call([])
        |> put_req_header(@device_id_key, "device")
        |> put_req_header(@app_version_key, "version")
        |> put_req_header(@os_key, "os")
        |> put_req_header(@language_key, "lang")
        |> DeviceInfoPlug.call(nil)

      device1 = Map.get(conn1.assigns, :dsc_device)

      conn2 =
        conn
        |> TestHelpers.put_auth_header(user)
        |> AuthenticationPlug.call([])
        |> put_req_header(@device_id_key, "device")
        |> put_req_header(@app_version_key, "version2")
        |> put_req_header(@os_key, "os2")
        |> put_req_header(@language_key, "lang2")
        |> DeviceInfoPlug.call(nil)

      device2 = Map.get(conn2.assigns, :dsc_device)

      assert device1.id == device2.id
      assert device1.app_version == "version"
      assert device1.device_id == "device"
      assert device1.device_os == "os"
      assert device1.device_language == "lang"

      assert device2.app_version == "version2"
      assert device2.device_id == "device"
      assert device2.device_os == "os2"
      assert device2.device_language == "lang2"
    end

    test "adds new record with new device_id for same user", %{conn: conn} do
      user = Factory.create_user()

      conn1 =
        conn
        |> TestHelpers.put_auth_header(user)
        |> AuthenticationPlug.call([])
        |> put_req_header(@device_id_key, "device")
        |> put_req_header(@app_version_key, "version")
        |> put_req_header(@os_key, "os")
        |> put_req_header(@language_key, "lang")
        |> DeviceInfoPlug.call(nil)

      device1 = Map.get(conn1.assigns, :dsc_device)

      conn2 =
        conn
        |> TestHelpers.put_auth_header(user)
        |> AuthenticationPlug.call([])
        |> put_req_header(@device_id_key, "device2")
        |> put_req_header(@app_version_key, "version2")
        |> put_req_header(@os_key, "os2")
        |> put_req_header(@language_key, "lang2")
        |> DeviceInfoPlug.call(nil)

      device2 = Map.get(conn2.assigns, :dsc_device)

      assert device1.id != device2.id
      assert device1.app_version == "version"
      assert device1.device_id == "device"
      assert device1.device_os == "os"
      assert device1.device_language == "lang"

      assert device2.app_version == "version2"
      assert device2.device_id == "device2"
      assert device2.device_os == "os2"
      assert device2.device_language == "lang2"
    end

    test "adds new record with same device_id for different user", %{conn: conn} do
      user1 = Factory.create_user()
      user2 = Factory.create_user()

      conn1 =
        conn
        |> TestHelpers.put_auth_header(user1)
        |> AuthenticationPlug.call([])
        |> put_req_header(@device_id_key, "device")
        |> put_req_header(@app_version_key, "version")
        |> put_req_header(@os_key, "os")
        |> put_req_header(@language_key, "lang")
        |> DeviceInfoPlug.call(nil)

      device1 = Map.get(conn1.assigns, :dsc_device)

      conn2 =
        conn
        |> TestHelpers.put_auth_header(user2)
        |> AuthenticationPlug.call([])
        |> put_req_header(@device_id_key, "device")
        |> put_req_header(@app_version_key, "version")
        |> put_req_header(@os_key, "os")
        |> put_req_header(@language_key, "lang")
        |> DeviceInfoPlug.call(nil)

      device2 = Map.get(conn2.assigns, :dsc_device)

      assert device1.id != device2.id
      assert device1.user_id == user1.id
      assert device2.user_id == user2.id

      assert device1.app_version == "version"
      assert device1.device_id == "device"
      assert device1.device_os == "os"
      assert device1.device_language == "lang"

      assert device2.app_version == "version"
      assert device2.device_id == "device"
      assert device2.device_os == "os"
      assert device2.device_language == "lang"
    end
  end
end
