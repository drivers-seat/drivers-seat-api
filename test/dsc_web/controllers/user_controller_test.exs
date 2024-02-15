defmodule DriversSeatCoopWeb.UserControllerTest do
  use DriversSeatCoopWeb.ConnCase, async: true
  use Oban.Testing, repo: DriversSeatCoop.Repo

  alias DriversSeatCoop.Accounts

  @create_attrs %{
    email: "some@example.com",
    password: "password",
    timezone: "America/Chicago",
    timezone_device: "US/Mountain",
    first_name: "some first name",
    last_name: "some last name",
    vehicle_make: "some vehicle make",
    vehicle_model: "some vehicle model",
    vehicle_type: "car",
    vehicle_year: 2019,
    service_names: ["food delivery"],
    ethnicity: ["Asian America", "Native American"],
    focus_group: "Seattle",
    engine_type: "17",
    country: "CA",
    opted_out_of_data_sale_at: "2019-11-03 12:00:00",
    opted_out_of_sensitive_data_use_at: "2022-12-01 13:15:00",
    postal_code: "33333"
  }
  @update_attrs %{
    email: "some_updated@example.com",
    password: "some password",
    timezone: "Jamaica",
    timezone_device: "America/New_York",
    first_name: "some updated name",
    last_name: "some updated last name",
    vehicle_make: "some updated vehicle make",
    vehicle_model: "some updated vehicle model",
    vehicle_type: "bike",
    vehicle_year: 2020,
    service_names: ["updated food delivery"],
    ethnicity: ["Pacific Islander American"],
    focus_group: "Seattle",
    engine_type: "18",
    opted_out_of_data_sale_at: "2019-12-03 12:00:00",
    opted_out_of_sensitive_data_use_at: "2022-10-15 10:15:00",
    country: "US",
    postal_code: "53202"
  }

  @invalid_attrs_email %{email: nil}

  @device_id_key "dsc-device-id"
  @device_id_1 "device1"
  @device_id_2 "device2"

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "create user" do
    test "renders user when data is valid", %{conn: conn} do
      create_conn = post(conn, Routes.user_path(conn, :create), user: @create_attrs)
      assert %{"id" => id} = json_response(create_conn, 201)["data"]
      user = Accounts.get_user!(id)

      conn =
        TestHelpers.put_auth_header(conn, user)
        |> get(Routes.user_path(conn, :show, id))

      assert %{
               "id" => ^id,
               "email" => "some@example.com",
               "enabled_features" => [],
               "timezone" => "America/Chicago",
               "timezone_device" => "US/Mountain",
               "first_name" => "some first name",
               "last_name" => "some last name",
               "vehicle_make" => "some vehicle make",
               "vehicle_model" => "some vehicle model",
               "vehicle_type" => "car",
               "vehicle_year" => 2019,
               "service_names" => ["food delivery"],
               "ethnicity" => ["Asian America", "Native American"],
               "focus_group" => "Seattle",
               "engine_type" => "17",
               "country" => "CA",
               "opted_out_of_data_sale_at" => "2019-11-03T12:00:00.000000",
               "opted_out_of_sensitive_data_use_at" => "2022-12-01T13:15:00.000000",
               "currently_on_shift" => nil,
               "postal_code" => "33333"
             } = json_response(conn, 200)["data"]

      today = NaiveDateTime.utc_now()
      assert NaiveDateTime.diff(user.opted_out_of_data_sale_at, today, :second) < 60 * 60
      assert NaiveDateTime.diff(user.opted_out_of_sensitive_data_use_at, today, :second) < 60 * 60
    end

    test "renders errors when email is empty", %{conn: conn} do
      test_user = Map.merge(@create_attrs, @invalid_attrs_email)

      conn = post(conn, Routes.user_path(conn, :create), user: test_user)
      assert json_response(conn, 422)
    end
  end

  describe "show user" do
    test "renders current shift when a shift is unfinished", %{conn: conn} do
      user = Factory.create_user()
      user_id = user.id

      # this shift is unfinished
      shift =
        Factory.create_shift(%{
          user_id: user.id,
          start_time: ~U[2022-02-17 01:01:01Z],
          end_time: nil
        })

      shift_id = shift.id

      conn =
        TestHelpers.put_auth_header(conn, user)
        |> get(Routes.user_path(conn, :show, user.id))

      assert %{
               "id" => ^user_id,
               "currently_on_shift" => ^shift_id
             } = json_response(conn, 200)["data"]
    end

    test "shifts have affinity to the device - match", %{conn: conn} do
      user = Factory.create_user()
      user_id = user.id

      device = Factory.create_device(user_id, @device_id_1)

      # this shift is unfinished
      shift =
        Factory.create_shift(%{
          user_id: user.id,
          start_time: ~U[2022-02-17 01:01:01Z],
          end_time: nil,
          device_id: device.id
        })

      assert not is_nil(shift.device_id)

      shift_id = shift.id

      conn = put_req_header(conn, @device_id_key, @device_id_1)

      conn =
        TestHelpers.put_auth_header(conn, user)
        |> get(Routes.user_path(conn, :show, user.id))

      assert %{
               "id" => ^user_id,
               "currently_on_shift" => ^shift_id
             } = json_response(conn, 200)["data"]
    end

    test "shifts have affinity to the device - mismatch", %{conn: conn} do
      user = Factory.create_user()
      user_id = user.id

      device = Factory.create_device(user_id, @device_id_2)

      # this shift is unfinished
      shift =
        Factory.create_shift(%{
          user_id: user.id,
          start_time: ~U[2022-02-17 01:01:01Z],
          end_time: nil,
          device_id: device.id
        })

      assert not is_nil(shift.device_id)

      conn = put_req_header(conn, @device_id_key, @device_id_1)

      conn =
        TestHelpers.put_auth_header(conn, user)
        |> get(Routes.user_path(conn, :show, user.id))

      assert %{
               "id" => ^user_id,
               "currently_on_shift" => nil
             } = json_response(conn, 200)["data"]
    end

    test "shifts have affinity to the device - null/device combo", %{conn: conn} do
      user = Factory.create_user()
      user_id = user.id

      Factory.create_device(user_id, @device_id_1)

      # this shift is unfinished
      shift =
        Factory.create_shift(%{
          user_id: user.id,
          start_time: ~U[2022-02-17 01:01:01Z],
          end_time: nil
        })

      shift_id = shift.id

      assert is_nil(shift.device_id)

      conn = put_req_header(conn, @device_id_key, @device_id_1)

      conn =
        TestHelpers.put_auth_header(conn, user)
        |> get(Routes.user_path(conn, :show, user_id))

      assert %{
               "id" => ^user_id,
               "currently_on_shift" => ^shift_id
             } = json_response(conn, 200)["data"]
    end

    test "if multiple shifts are open, older shift is selected", %{conn: conn} do
      user = Factory.create_user()
      user_id = user.id

      # this shift is unfinished
      shift_1 =
        Factory.create_shift(%{
          user_id: user.id,
          start_time: ~U[2022-02-17 01:01:01Z],
          end_time: nil
        })

      _shift_2 =
        Factory.create_shift(%{
          user_id: user.id,
          start_time: ~U[2022-02-18 02:01:01Z],
          end_time: nil
        })

      shift_1_id = shift_1.id

      conn =
        TestHelpers.put_auth_header(conn, user)
        |> get(Routes.user_path(conn, :show, user_id))

      assert %{
               "id" => ^user_id,
               "currently_on_shift" => ^shift_1_id
             } = json_response(conn, 200)["data"]
    end

    test "admin user has ghosting feature enabled", %{conn: conn} do
      user = Factory.create_admin_user()
      user_id = user.id

      conn =
        TestHelpers.put_auth_header(conn, user)
        |> get(Routes.user_path(conn, :show, user.id))

      assert %{
               "id" => ^user_id,
               "enabled_features" => ["ghosting"]
             } = json_response(conn, 200)["data"]
    end
  end

  describe "update user" do
    test "renders user when data is valid", %{conn: conn} do
      %{id: id} = user = Factory.create_user()

      update_conn =
        TestHelpers.put_auth_header(conn, user)
        |> put(Routes.user_path(conn, :update, user), user: @update_attrs)

      assert %{
               "id" => ^id,
               "email" => "some_updated@example.com",
               "enabled_features" => [],
               "timezone" => "Jamaica",
               "timezone_device" => "America/New_York"
             } = json_response(update_conn, 200)["data"]

      conn =
        TestHelpers.put_auth_header(conn, user)
        |> get(Routes.user_path(conn, :show, user.id))

      assert %{
               "id" => ^id,
               "email" => "some_updated@example.com",
               "enabled_features" => [],
               "timezone" => "Jamaica",
               "timezone_device" => "America/New_York",
               "first_name" => "some updated name",
               "last_name" => "some updated last name",
               "vehicle_make" => "some updated vehicle make",
               "vehicle_model" => "some updated vehicle model",
               "vehicle_type" => "bike",
               "vehicle_year" => 2020,
               "service_names" => ["updated food delivery"],
               "ethnicity" => ["Pacific Islander American"],
               "focus_group" => "Seattle",
               "engine_type" => "18",
               "opted_out_of_data_sale_at" => "2019-12-03T12:00:00.000000",
               "opted_out_of_sensitive_data_use_at" => "2022-10-15T10:15:00.000000",
               "currently_on_shift" => nil,
               "country" => "US",
               "postal_code" => "53202"
             } = json_response(conn, 200)["data"]

      assert {:ok, user} =
               Accounts.get_user_by_email_and_password(
                 "some_updated@example.com",
                 "some password"
               )

      assert user.id == id

      today = NaiveDateTime.utc_now()
      assert NaiveDateTime.diff(user.opted_out_of_data_sale_at, today, :second) < 10
      assert NaiveDateTime.diff(user.opted_out_of_sensitive_data_use_at, today, :second) < 10
    end

    test "renders errors when email is empty", %{conn: conn} do
      user = Factory.create_user()

      test_user = Map.merge(@update_attrs, @invalid_attrs_email)

      conn =
        TestHelpers.put_auth_header(conn, user)
        |> put(Routes.user_path(conn, :update, user), user: test_user)

      assert json_response(conn, 422)
    end

    test "renders errors when email is duplicated", %{conn: conn} do
      user_1 = Factory.create_user()
      user_2 = Factory.create_user()

      conn =
        TestHelpers.put_auth_header(conn, user_2)
        |> put(Routes.user_path(conn, :update, user_2), user: %{email: user_1.email})

      assert json_response(conn, 422)
    end

    test "accepts RFC-1123 like date for opted_out_of_data_sale_at", %{conn: conn} do
      %{id: id} = user = Factory.create_user()

      conn =
        TestHelpers.put_auth_header(conn, user)
        |> put(Routes.user_path(conn, :update, user),
          user: %{opted_out_of_data_sale_at: "Mon Dec 05 2022 14:00:02 GMT-0800"}
        )

      assert %{
               "id" => ^id,
               "opted_out_of_data_sale_at" => "2022-12-05T22:00:02.000000"
             } = json_response(conn, 200)["data"]
    end
  end

  describe "delete user" do
    test "delete user", %{conn: conn} do
      user = Factory.create_user()

      conn =
        TestHelpers.put_auth_header(conn, user)
        |> delete(Routes.user_path(conn, :delete, user.id))

      # empty response with status 204
      assert response(conn, 204)
    end
  end
end
