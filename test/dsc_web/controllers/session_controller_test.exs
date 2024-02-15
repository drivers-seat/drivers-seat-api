defmodule DriversSeatCoopWeb.SessionControllerTest do
  use DriversSeatCoopWeb.ConnCase, async: true

  alias DriversSeatCoop.Accounts

  @invalid_attrs %{email: nil, password: nil}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "create session" do
    test "renders nothing and has auth header when data is valid", %{conn: conn} do
      user = Factory.create_user(password: "password")
      user_id = user.id
      params = %{email: user.email, password: "password"}
      conn = post(conn, Routes.session_path(conn, :create), session: params)
      assert json_response(conn, 200)
      assert ["Bearer " <> token] = Plug.Conn.get_resp_header(conn, "authorization")

      assert {:ok, %{user_id: ^user_id}} = Accounts.verify_token(token)
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.user_path(conn, :create), user: @invalid_attrs)
      assert json_response(conn, 422)
    end

    test "renders errors when user is deleted", %{conn: conn} do
      user = Factory.create_deleted_user(password: "password")
      params = %{email: user.email, password: "password"}
      conn = post(conn, Routes.session_path(conn, :create), session: params)
      assert json_response(conn, 401)
    end
  end

  describe "get session" do
    test "renders nothing and has auth header when data is valid", %{conn: conn} do
      user = Factory.create_user(password: "password")
      user_id = user.id

      conn =
        TestHelpers.put_auth_header(conn, user)
        |> get(Routes.session_path(conn, :index))

      assert json_response(conn, 200)
      assert ["Bearer " <> token] = Plug.Conn.get_resp_header(conn, "authorization")
      assert {:ok, %{user_id: ^user_id}} = Accounts.verify_token(token)
    end

    test "renders errors when not logged in", %{conn: conn} do
      conn = get(conn, Routes.session_path(conn, :index))
      assert json_response(conn, 401)
    end
  end

  describe "ghost admin user" do
    test "renders nothing and has auth header when data is valid", %{conn: conn} do
      user = Factory.create_admin_user()
      user_id = user.id

      ghost_user = Factory.create_user(password: "password")
      ghost_user_id = ghost_user.id

      conn = TestHelpers.put_auth_header(conn, user)

      conn1 = get(conn, Routes.session_path(conn, :index))

      assert json_response(conn1, 200)
      assert ["Bearer " <> token] = Plug.Conn.get_resp_header(conn1, "authorization")
      assert {:ok, %{user_id: ^user_id}} = Accounts.verify_token(token)

      conn2 =
        post(conn, Routes.session_path(conn, :ghost_admin_user), %{"user_id" => ghost_user_id})

      assert json_response(conn2, 200)
      assert ["Bearer " <> token] = Plug.Conn.get_resp_header(conn2, "authorization")
      assert {:ok, %{user_id: ^ghost_user_id}} = Accounts.verify_token(token)
    end

    test "renders errors when not logged in", %{conn: conn} do
      conn = get(conn, Routes.session_path(conn, :index))
      assert json_response(conn, 401)
    end

    test "renders correctly when not admin", %{conn: conn} do
      user = Factory.create_user()

      ghost_user = Factory.create_user(password: "password")
      ghost_user_id = ghost_user.id

      conn = TestHelpers.put_auth_header(conn, user)

      conn2 =
        post(conn, Routes.session_path(conn, :ghost_admin_user), %{"user_id" => ghost_user_id})

      assert json_response(conn2, 404)
    end
  end
end
