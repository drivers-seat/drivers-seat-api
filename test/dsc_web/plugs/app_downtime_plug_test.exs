defmodule DriversSeatCoopWeb.AppDowntimePlugTest do
  # this test CANNOT run async along with the other tests.
  # It changes configuration and will cause intermittent failures if running
  # asynchroniously
  use DriversSeatCoopWeb.ConnCase, async: false

  alias DriversSeatCoop.Accounts
  alias DriversSeatCoopWeb.AuthenticationPlug

  @uptime_config [
    is_downtime?: false,
    allow_admins?: false,
    downtime_message: nil
  ]

  @downtime_title_no_admins "No Access"
  @downtime_message_no_admins "Test Downtime no admins"
  @downtime_config_no_admins [
    is_downtime?: true,
    allow_admins?: false,
    downtime_message: @downtime_message_no_admins,
    downtime_title: @downtime_title_no_admins
  ]

  @downtime_title_allow_admins "Admin Only"
  @downtime_message_allow_admins "Test Downtime with admins"
  @downtime_config_allow_admins [
    is_downtime?: true,
    allow_admins?: true,
    downtime_message: @downtime_message_allow_admins,
    downtime_title: @downtime_title_allow_admins
  ]

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}

    # clean up our config after each test in this suite
    on_exit(fn ->
      clear_env_downtime()
    end)
  end

  describe "test plug" do
    test "Works as expected", %{conn: conn} do
      user = Factory.create_user()

      # no config exists, app should be up
      clear_env_downtime()
      assert Application.get_env(:dsc, DriversSeatCoopWeb.AppDowntimePlug) == nil

      result_conn =
        conn
        |> TestHelpers.put_auth_header(user)
        |> AuthenticationPlug.call([])
        |> get(Routes.session_path(conn, :index))

      assert json_response(result_conn, 200)

      # add downtime config, app should be down
      set_env_downtime(@downtime_config_no_admins)

      result_conn =
        conn
        |> TestHelpers.put_auth_header(user)
        |> AuthenticationPlug.call([])
        |> get(Routes.session_path(conn, :index))

      assert json_response(result_conn, 503)

      # add sepcific uptime config, app should be up
      set_env_downtime(@uptime_config)

      result_conn =
        conn
        |> TestHelpers.put_auth_header(user)
        |> AuthenticationPlug.call([])
        |> get(Routes.session_path(conn, :index))

      assert json_response(result_conn, 200)
    end

    test "Allows admin user in when allow_admins? config value is set", %{conn: conn} do
      admin_user = Factory.create_admin_user()
      normal_user = Factory.create_user()

      # validate that users are setup correctly
      assert Accounts.is_admin?(admin_user)
      assert not Accounts.is_admin?(normal_user)

      # validate they can make calls when there's no downtime
      result_conn =
        conn
        |> TestHelpers.put_auth_header(admin_user)
        |> AuthenticationPlug.call([])
        |> get(Routes.session_path(conn, :index))

      assert json_response(result_conn, 200)

      result_conn =
        conn
        |> TestHelpers.put_auth_header(normal_user)
        |> AuthenticationPlug.call([])
        |> get(Routes.session_path(conn, :index))

      assert json_response(result_conn, 200)

      # set downtime for all users and ensure that 503 is returned
      set_env_downtime(@downtime_config_no_admins)

      result_conn =
        conn
        |> TestHelpers.put_auth_header(admin_user)
        |> AuthenticationPlug.call([])
        |> get(Routes.session_path(conn, :index))

      assert json_response(result_conn, 503)

      result_conn =
        conn
        |> TestHelpers.put_auth_header(normal_user)
        |> AuthenticationPlug.call([])
        |> get(Routes.session_path(conn, :index))

      assert json_response(result_conn, 503)

      # set downtime for non-admin users and ensure that 503 is returned
      # only fro non-admin user
      set_env_downtime(@downtime_config_allow_admins)

      result_conn =
        conn
        |> TestHelpers.put_auth_header(admin_user)
        |> AuthenticationPlug.call([])
        |> get(Routes.session_path(conn, :index))

      assert json_response(result_conn, 200)

      result_conn =
        conn
        |> TestHelpers.put_auth_header(normal_user)
        |> AuthenticationPlug.call([])
        |> get(Routes.session_path(conn, :index))

      assert json_response(result_conn, 503)
    end

    test "Info is returned correctly on downtime - no admins", %{conn: conn} do
      user = Factory.create_user()

      set_env_downtime(@downtime_config_no_admins)

      result_conn =
        conn
        |> TestHelpers.put_auth_header(user)
        |> AuthenticationPlug.call([])
        |> get(Routes.session_path(conn, :index))

      expected_message = @downtime_message_no_admins
      expected_title = @downtime_title_no_admins

      assert %{
               "errors" => %{
                 "admin_only" => false,
                 "title" => ^expected_title,
                 "message" => ^expected_message
               }
             } = json_response(result_conn, 503)
    end

    test "Info is returned correctly on downtime - allow admins", %{conn: conn} do
      user = Factory.create_user()

      set_env_downtime(@downtime_config_allow_admins)

      result_conn =
        conn
        |> TestHelpers.put_auth_header(user)
        |> AuthenticationPlug.call([])
        |> get(Routes.session_path(conn, :index))

      expected_message = @downtime_message_allow_admins
      expected_title = @downtime_title_allow_admins

      assert %{
               "errors" => %{
                 "admin_only" => true,
                 "title" => ^expected_title,
                 "message" => ^expected_message
               }
             } = json_response(result_conn, 503)
    end
  end

  defp clear_env_downtime do
    Application.delete_env(:dsc, DriversSeatCoopWeb.AppDowntimePlug)
  end

  defp set_env_downtime(config),
    do: Application.put_env(:dsc, DriversSeatCoopWeb.AppDowntimePlug, config)
end
