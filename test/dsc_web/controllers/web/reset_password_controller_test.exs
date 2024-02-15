defmodule DriversSeatCoopWeb.Web.ResetPasswordControllerTest do
  use DriversSeatCoopWeb.ConnCase

  alias DriversSeatCoop.Accounts

  describe "edit reset_password" do
    test "renders form for editing chosen reset_password", %{conn: conn} do
      user = Factory.create_user()
      {:ok, user} = Accounts.reset_password_user(user)
      conn = get(conn, Routes.web_reset_password_path(conn, :edit, user.reset_password_token))
      assert html_response(conn, 200) =~ "Update Password"
    end
  end

  describe "update reset_password" do
    test "redirects when data is valid", %{conn: conn} do
      user = Factory.create_user(%{password: "a password"})
      {:ok, user} = Accounts.reset_password_user(user)

      conn =
        put conn, Routes.web_reset_password_path(conn, :update, user.reset_password_token),
          user: %{password: "mypassword"}

      user = Accounts.get_user!(user.id)

      assert html_response(conn, 200) =~ "Reset password successfully"
      assert {:ok, user} == Accounts.get_user_by_email_and_password(user.email, "mypassword")
    end

    test "renders errors when data is invalid", %{conn: conn} do
      user = Factory.create_user(%{password: "a password"})
      {:ok, user} = Accounts.reset_password_user(user)

      conn =
        put conn, Routes.web_reset_password_path(conn, :update, user.reset_password_token),
          user: %{password: ""}

      assert html_response(conn, 200) =~ "Update Password"
    end
  end
end
