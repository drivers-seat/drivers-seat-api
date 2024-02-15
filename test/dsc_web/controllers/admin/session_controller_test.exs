defmodule DriversSeatCoopWeb.Admin.SessionControllerTest do
  use DriversSeatCoopWeb.ConnCase

  describe "new session" do
    test "renders form", %{conn: conn} do
      conn = get(conn, Routes.admin_session_path(conn, :new))
      assert html_response(conn, 200) =~ "Email"
      assert html_response(conn, 200) =~ "Password"
    end
  end

  describe "create session" do
    test "redirects when data is valid", %{conn: conn} do
      admin = Factory.create_admin_user(password: "password")

      conn =
        post(conn, Routes.admin_session_path(conn, :create), %{
          email: admin.email,
          password: "password"
        })

      assert redirected_to(conn) == Routes.admin_page_path(conn, :index)
      assert Plug.Conn.get_session(conn, :user_id) == admin.id
    end

    test "renders errors when data is invalid", %{conn: conn} do
      admin = Factory.create_admin_user(password: "password")

      conn =
        post(conn, Routes.admin_session_path(conn, :create), %{
          email: admin.email,
          password: "password2"
        })

      refute Plug.Conn.get_session(conn, :user_id)
      assert html_response(conn, 200) =~ admin.email
      assert html_response(conn, 200) =~ "Password"
    end
  end

  describe "logout" do
    test "logs out", %{conn: conn} do
      conn = delete(conn, Routes.admin_session_path(conn, :logout))
      assert redirected_to(conn) == Routes.admin_session_path(conn, :new)
    end
  end
end
