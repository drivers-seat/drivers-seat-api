defmodule DriversSeatCoopWeb.AppPreferencesControllerTest do
  use DriversSeatCoopWeb.ConnCase, async: true

  alias DriversSeatCoop.AppPreferences
  alias DriversSeatCoop.TestHelpers

  @min_app_version "4.0.1"

  @pref_1 %{
    :key => "key1",
    :last_updated_app_version => "2.0.29",
    :last_updated_device_id => "123456",
    :value => %{
      "prop1" => "key1_val1",
      "prop2" => "key1_val2"
    }
  }

  @pref_2 %{
    :key => "key2",
    :last_updated_app_version => "3.0.0",
    :last_updated_device_id => "89065434",
    :value => %{
      "prop1" => "key2_val1",
      "prop2" => "key2_val2"
    }
  }

  setup %{conn: conn} do
    user = Factory.create_user()

    conn =
      put_req_header(conn, "accept", "application/json")
      |> TestHelpers.put_auth_header(user)

    {:ok, conn: conn, user: user}
  end

  describe "index" do
    test "lists user's application preferences", %{conn: conn, user: user} do
      {:ok, _} =
        AppPreferences.set_user_app_preference(user.id, %{
          device_id: @pref_1.last_updated_device_id,
          app_version: @pref_1.last_updated_app_version,
          key: @pref_1.key,
          value: @pref_1.value
        })

      default_prefs =
        AppPreferences.get_default_preference_values(user.id)
        |> Enum.map(fn p ->
          Map.take(p, [:key, :last_updated_app_version, :last_updated_device_id, :value])
        end)

      AppPreferences.set_user_app_preference(user.id, %{
        device_id: @pref_2.last_updated_device_id,
        app_version: @pref_2.last_updated_app_version,
        key: @pref_2.key,
        value: @pref_2.value
      })

      conn = get(conn, Routes.app_preferences_path(conn, :index))

      expected =
        ([@pref_1, @pref_2] ++ default_prefs)
        |> Jason.encode!()
        |> Jason.decode!()
        |> Enum.sort_by(fn x -> "#{Map.get(x, "key")}" end)

      actual =
        json_response(conn, 200)["data"]
        |> Enum.sort_by(fn x -> "#{Map.get(x, "key")}" end)

      assert Enum.count(actual) == 2 + Enum.count(default_prefs)
      assert expected == actual
    end
  end

  describe "update" do
    test "updates value as expected", %{conn: conn, user: user} do
      value = %{"prop1" => "key1_val1"}

      default_prefs =
        AppPreferences.get_default_preference_values(user.id)
        |> Enum.map(fn p ->
          Map.take(p, [:key, :last_updated_app_version, :last_updated_device_id, :value])
        end)

      conn =
        conn
        |> Plug.Conn.put_req_header("dsc-app-version", @min_app_version)
        |> Plug.Conn.put_req_header("dsc-device-id", "abcd-efgh")
        |> put(Routes.app_preferences_path(conn, :update, "key1"), value: value)

      expected =
        ([
           %{
             "key" => "key1",
             "last_updated_app_version" => @min_app_version,
             "last_updated_device_id" => "abcd-efgh",
             "value" => %{"prop1" => "key1_val1"}
           }
         ] ++ default_prefs)
        |> Jason.encode!()
        |> Jason.decode!()
        |> Enum.sort_by(fn x -> "#{Map.get(x, "key")}" end)

      actual =
        json_response(conn, 200)["data"]
        |> Enum.sort_by(fn x -> "#{Map.get(x, "key")}" end)

      assert expected == actual
    end

    test "honors user value over default value", %{conn: conn, user: user} do
      default_prefs =
        AppPreferences.get_default_preference_values(user.id)
        |> Enum.map(fn p ->
          Map.take(p, [:key, :last_updated_app_version, :last_updated_device_id, :value])
        end)

      changed_pref = Enum.at(default_prefs, 0)

      value = %{"prop1" => "key1_val1"}

      conn =
        conn
        |> Plug.Conn.put_req_header("dsc-app-version", @min_app_version)
        |> Plug.Conn.put_req_header("dsc-device-id", "abcd-efgh")
        |> put(Routes.app_preferences_path(conn, :update, changed_pref.key), value: value)

      expected =
        ([
           %{
             "key" => changed_pref.key,
             "last_updated_app_version" => @min_app_version,
             "last_updated_device_id" => "abcd-efgh",
             "value" => %{"prop1" => "key1_val1"}
           }
         ] ++ Enum.slice(default_prefs, 1, 1000))
        |> Jason.encode!()
        |> Jason.decode!()
        |> Enum.sort_by(fn x -> "#{Map.get(x, "key")}" end)

      actual =
        json_response(conn, 200)["data"]
        |> Enum.sort_by(fn x -> "#{Map.get(x, "key")}" end)

      assert expected == actual
    end

    test "renders error when missing header dsc-app-version", %{conn: conn, user: _user} do
      conn =
        conn
        |> Plug.Conn.put_req_header("dsc-device-id", "123456")
        |> put(Routes.app_preferences_path(conn, :update, "key1"), value: %{prop1: "key1_val1"})

      assert json_response(conn, 422)
    end

    test "renders error when missing header dsc-device-id", %{conn: conn, user: _user} do
      conn =
        conn
        |> Plug.Conn.put_req_header("dsc-app-version", "123456")
        |> put(Routes.app_preferences_path(conn, :update, "key1"), value: %{prop1: "key1_val1"})

      assert json_response(conn, 422)
    end

    test "renders error when value is nil", %{conn: conn, user: _user} do
      conn =
        conn
        |> Plug.Conn.put_req_header("dsc-device-id", "123456")
        |> Plug.Conn.put_req_header("dsc-app-version", "123456")
        |> put(Routes.app_preferences_path(conn, :update, "key1"), value: nil)

      assert json_response(conn, 422)
    end
  end
end
