defmodule DriversSeatCoopWeb.Admin.UserControllerTest do
  use DriversSeatCoopWeb.ConnCase, async: true
  use Oban.Testing, repo: DriversSeatCoop.Repo

  alias DriversSeatCoop.Accounts
  alias DriversSeatCoop.Argyle.Oban.{BackfillArgyleActivities, ImportArgyleProfileInformation}

  @create_attrs %{
    argyle_token: "some argyle_token",
    argyle_user_id: "some argyle_user_id",
    car_ownership: "some car_ownership",
    contact_permission: true,
    country: "some country",
    country_argyle: "some country_argyle",
    deleted: true,
    device_platform: "some device_platform",
    email: "email@example.com",
    engine_type: "some engine_type",
    first_name: "some first_name",
    focus_group: "some focus_group",
    last_name: "some last_name",
    password: "password",
    phone_number: "some phone_number",
    postal_code: "some postal_code",
    postal_code_argyle: "some postal_code_argyle",
    role: nil,
    timezone: "America/Chicago",
    timezone_argyle: "America/New_York",
    timezone_device: "America/Cancun",
    vehicle_make: "some vehicle_make",
    vehicle_make_argyle: "some vehicle_make_argyle",
    vehicle_model: "some vehicle_model",
    vehicle_model_argyle: "some vehicle_model_argyle",
    vehicle_type: "car",
    vehicle_year: 42,
    vehicle_year_argyle: 42
  }
  @update_attrs %{
    argyle_token: "some updated argyle_token",
    argyle_user_id: "some updated argyle_user_id",
    car_ownership: "some updated car_ownership",
    contact_permission: false,
    country: "some updated country",
    country_argyle: "some updated country_argyle",
    deleted: false,
    device_platform: "some updated device_platform",
    email: "something@example.com",
    engine_type: "some updated engine_type",
    first_name: "some updated first_name",
    focus_group: "some updated focus_group",
    last_name: "some updated last_name",
    phone_number: "some updated phone_number",
    postal_code: "some updated postal_code",
    postal_code_argyle: "some updated postal_code_argyle",
    role: "admin",
    timezone: "America/Cayenne",
    timezone_argyle: "America/Phoenix",
    timezone_device: "America/Yellowknife",
    vehicle_make: "some updated vehicle_make",
    vehicle_make_argyle: "some updated vehicle_make_argyle",
    vehicle_model: "some updated vehicle_model",
    vehicle_model_argyle: "some updated vehicle_model_argyle",
    vehicle_type: "bike",
    vehicle_year: 43,
    vehicle_year_argyle: 43
  }
  @invalid_attrs %{
    argyle_token: nil,
    argyle_user_id: nil,
    car_ownership: nil,
    contact_permission: nil,
    country: nil,
    country_argyle: nil,
    deleted: nil,
    device_platform: nil,
    email: nil,
    engine_type: nil,
    first_name: nil,
    focus_group: nil,
    last_name: nil,
    phone_number: nil,
    postal_code: nil,
    postal_code_argyle: nil,
    role: nil,
    timezone: nil,
    timezone_argyle: nil,
    timezone_device: nil,
    vehicle_make: nil,
    vehicle_make_argyle: nil,
    vehicle_model: nil,
    vehicle_model_argyle: nil,
    vehicle_type: nil,
    vehicle_year: nil,
    vehicle_year_argyle: nil
  }

  defp admin_session(state) do
    admin = Factory.create_admin_user()
    conn = TestHelpers.put_admin_session(state.conn, admin)

    {:ok, conn: conn, admin: admin}
  end

  def fixture(:user) do
    {:ok, user} = Accounts.create_user(@create_attrs)
    user
  end

  describe "index" do
    setup [:admin_session]

    test "lists all users", %{conn: conn} do
      conn = get(conn, Routes.admin_user_path(conn, :index))
      assert html_response(conn, 200) =~ "Users"
    end
  end

  describe "new user" do
    setup [:admin_session]

    test "renders form", %{conn: conn} do
      conn = get(conn, Routes.admin_user_path(conn, :new))
      assert html_response(conn, 200) =~ "New User"
    end
  end

  describe "create user" do
    setup [:admin_session]

    test "redirects to show when data is valid", %{conn: conn} do
      conn = post conn, Routes.admin_user_path(conn, :create), user: @create_attrs

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.admin_user_path(conn, :show, id)

      conn = get(conn, Routes.admin_user_path(conn, :show, id))
      assert html_response(conn, 200) =~ "User Details"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, Routes.admin_user_path(conn, :create), user: @invalid_attrs
      assert html_response(conn, 200) =~ "New User"
    end
  end

  describe "edit user" do
    setup [:admin_session, :create_user]

    test "renders form for editing chosen user", %{conn: conn, user: user} do
      conn = get(conn, Routes.admin_user_path(conn, :edit, user))
      assert html_response(conn, 200) =~ "Edit User"
    end
  end

  describe "update user" do
    setup [:admin_session, :create_user]

    test "redirects when data is valid", %{conn: conn, user: user} do
      conn = put conn, Routes.admin_user_path(conn, :update, user), user: @update_attrs
      assert redirected_to(conn) == Routes.admin_user_path(conn, :show, user)

      conn = get(conn, Routes.admin_user_path(conn, :show, user))
      assert html_response(conn, 200) =~ "some updated argyle_user_id"
    end

    test "renders errors when data is invalid", %{conn: conn, user: user} do
      conn = put conn, Routes.admin_user_path(conn, :update, user), user: @invalid_attrs
      assert html_response(conn, 200) =~ "Edit User"
    end
  end

  describe "delete user" do
    setup [:admin_session, :create_user]

    test "deletes chosen user", %{conn: conn, user: user} do
      conn = delete(conn, Routes.admin_user_path(conn, :delete, user))
      assert redirected_to(conn) == Routes.admin_user_path(conn, :index)

      # soft delete is performed
      updated_user = Accounts.get_user!(user.id)
      assert %{deleted: true} = updated_user
    end
  end

  describe "sync argyle" do
    setup [:admin_session, :create_user]

    test "syncs argyle user", %{conn: conn, user: user} do
      conn = post(conn, Routes.admin_user_path(conn, :sync_argyle, user))
      assert redirected_to(conn) == Routes.admin_user_path(conn, :show, user)
      assert_enqueued(worker: ImportArgyleProfileInformation, args: %{user_id: user.id})
      assert_enqueued(worker: BackfillArgyleActivities, args: %{user_id: user.id})
    end
  end

  defp create_user(_) do
    user = fixture(:user)
    {:ok, user: user}
  end
end
