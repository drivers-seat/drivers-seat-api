defmodule DriversSeatCoopWeb.OutOfDateAppVersionPlugTest do
  use DriversSeatCoopWeb.ConnCase, async: true

  alias DriversSeatCoop.Devices.Device
  alias DriversSeatCoopWeb.AuthenticationPlug
  alias DriversSeatCoopWeb.OutOfDateAppVersionPlug

  @app_version_key "dsc-app-version"
  @platform_key "dsc-device-platform"
  @min_allowed_version "4.0.0"

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}

    set_env()

    # clean up our config after each test in this suite
    on_exit(fn ->
      clear_env()
    end)
  end

  defp clear_env do
    Application.delete_env(:dsc, DriversSeatCoopWeb.OutOfDateAppVersionPlug)
  end

  defp set_env do
    Application.put_env(:dsc, DriversSeatCoopWeb.OutOfDateAppVersionPlug,
      min_version: @min_allowed_version,
      store_url_ios: "https://apple.com/store",
      store_url_android: "https://google.com/play",
      store_url_default: "https://iDontKnow.com"
    )
  end

  describe "call" do
    test "Bypasses check if BOTH platform and version are not available", %{conn: conn} do
      user = Factory.create_user()

      conn =
        conn
        |> TestHelpers.put_auth_header(user)
        |> AuthenticationPlug.call([])
        |> OutOfDateAppVersionPlug.call(nil)
        |> get(Routes.session_path(conn, :index))

      assert json_response(conn, 200)
    end

    test "Bypasses check if config value not available", %{conn: conn} do
      # remove the config setting
      clear_env()

      user = Factory.create_user()

      conn =
        conn
        |> TestHelpers.put_auth_header(user)
        |> AuthenticationPlug.call([])
        |> put_req_header(@app_version_key, "0.0.0")
        |> OutOfDateAppVersionPlug.call(nil)
        |> get(Routes.session_path(conn, :index))

      assert json_response(conn, 200)
    end

    test "Checks if EITHER platform or version are available - platform missing", %{conn: conn} do
      user = Factory.create_user()

      test_version = "2.9.9"
      assert Device.compare_version(test_version, @min_allowed_version) == :lt

      conn =
        conn
        |> TestHelpers.put_auth_header(user)
        |> AuthenticationPlug.call([])
        |> put_req_header(@app_version_key, test_version)
        |> OutOfDateAppVersionPlug.call(nil)
        |> get(Routes.session_path(conn, :index))

      assert json_response(conn, 426)
    end

    test "Checks if EITHER platform or version are available - version missing ", %{conn: conn} do
      user = Factory.create_user()

      conn =
        conn
        |> TestHelpers.put_auth_header(user)
        |> AuthenticationPlug.call([])
        |> put_req_header(@platform_key, "platform")
        |> OutOfDateAppVersionPlug.call(nil)
        |> get(Routes.session_path(conn, :index))

      assert json_response(conn, 426)
    end

    test "returns 426 on outdated version", %{conn: conn} do
      test_version = "2.9.9"
      assert Device.compare_version(test_version, @min_allowed_version) == :lt

      conn =
        conn
        |> put_req_header(@app_version_key, test_version)
        |> put_req_header(@platform_key, "platform")
        |> OutOfDateAppVersionPlug.call(nil)
        |> get(Routes.session_path(conn, :index))

      assert json_response(conn, 426)
    end

    test "no affect if version is up to date", %{conn: conn} do
      user = Factory.create_user()

      conn =
        conn
        |> TestHelpers.put_auth_header(user)
        |> AuthenticationPlug.call([])
        |> put_req_header(@app_version_key, @min_allowed_version)
        |> put_req_header(@platform_key, "platform")
        |> OutOfDateAppVersionPlug.call(nil)
        |> get(Routes.session_path(conn, :index))

      assert json_response(conn, 200)
    end

    test "no affect if version is greater than minimum version", %{conn: conn} do
      user = Factory.create_user()

      test_version = "5.0.1"
      assert Device.compare_version(test_version, @min_allowed_version) == :gt

      conn =
        conn
        |> TestHelpers.put_auth_header(user)
        |> AuthenticationPlug.call([])
        |> put_req_header(@app_version_key, test_version)
        |> put_req_header(@platform_key, "platform")
        |> OutOfDateAppVersionPlug.call(nil)
        |> get(Routes.session_path(conn, :index))

      assert json_response(conn, 200)
    end

    test "Failure response contains proper message", %{conn: conn} do
      user = Factory.create_user()

      test_version = "2.9.9"
      os = "ios"
      assert Device.compare_version(test_version, @min_allowed_version) == :lt

      conn =
        conn
        |> TestHelpers.put_auth_header(user)
        |> AuthenticationPlug.call([])
        |> put_req_header(@app_version_key, test_version)
        |> put_req_header(@platform_key, os)
        |> OutOfDateAppVersionPlug.call(nil)
        |> get(Routes.session_path(conn, :index))

      expected_title = "App version #{test_version} is no longer supported"
      min_app_version = @min_allowed_version

      assert %{
               "errors" => %{
                 "calling_os" => ^os,
                 "calling_version" => ^test_version,
                 "minimum_version" => ^min_app_version,
                 "title" => ^expected_title,
                 "message" =>
                   "Install the latest version to keep up to date on new features and bug fixes."
               }
             } = json_response(conn, 426)
    end

    test "Failure response contains proper store_url - ios", %{conn: conn} do
      user = Factory.create_user()

      test_version = "2.9.9"
      os = "ios"
      assert Device.compare_version(test_version, @min_allowed_version) == :lt

      conn =
        conn
        |> TestHelpers.put_auth_header(user)
        |> AuthenticationPlug.call([])
        |> put_req_header(@app_version_key, test_version)
        |> put_req_header(@platform_key, os)
        |> OutOfDateAppVersionPlug.call(nil)
        |> get(Routes.session_path(conn, :index))

      expected_url = OutOfDateAppVersionPlug.get_store_url_ios()

      assert %{
               "errors" => %{
                 "store_url" => ^expected_url
               }
             } = json_response(conn, 426)
    end

    test "Failure response contains proper store_url - android", %{conn: conn} do
      user = Factory.create_user()

      test_version = "2.9.9"
      os = "android"
      assert Device.compare_version(test_version, @min_allowed_version) == :lt

      conn =
        conn
        |> TestHelpers.put_auth_header(user)
        |> AuthenticationPlug.call([])
        |> put_req_header(@app_version_key, test_version)
        |> put_req_header(@platform_key, os)
        |> OutOfDateAppVersionPlug.call(nil)
        |> get(Routes.session_path(conn, :index))

      expected_url = OutOfDateAppVersionPlug.get_store_url_android()

      assert %{
               "errors" => %{
                 "store_url" => ^expected_url
               }
             } = json_response(conn, 426)
    end

    test "Failure response contains proper store_url - other", %{conn: conn} do
      user = Factory.create_user()

      test_version = "2.9.9"
      os = "web"
      assert Device.compare_version(test_version, @min_allowed_version) == :lt

      conn =
        conn
        |> TestHelpers.put_auth_header(user)
        |> AuthenticationPlug.call([])
        |> put_req_header(@app_version_key, test_version)
        |> put_req_header(@platform_key, os)
        |> OutOfDateAppVersionPlug.call(nil)
        |> get(Routes.session_path(conn, :index))

      expected_url = OutOfDateAppVersionPlug.get_store_url_other()

      assert %{
               "errors" => %{
                 "store_url" => ^expected_url
               }
             } = json_response(conn, 426)
    end
  end
end
