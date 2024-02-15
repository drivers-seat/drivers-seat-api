defmodule DriversSeatCoopWeb.ResetPasswordControllerTest do
  use DriversSeatCoopWeb.ConnCase

  alias DriversSeatCoop.Accounts
  alias DriversSeatCoop.Accounts.User
  import Swoosh.TestAssertions

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "create reset_password" do
    test "sends reset password email", %{conn: conn} do
      user = Factory.create_user(%{email: "test@rokkincat.com"})

      conn =
        conn
        |> post(
          Routes.reset_password_path(conn, :create, %{reset_password: %{email: user.email}})
        )

      assert %{"success" => true} = json_response(conn, 200)["data"]

      user = Accounts.get_user!(user.id)
      assert not is_nil(user.reset_password_token)
      assert not is_nil(user.reset_password_token_expires_at)

      assert_email_sent(
        subject: "Forgot Password",
        to: {User.name(user), user.email}
      )
    end

    test "does not send reset password email for invalid email", %{conn: conn} do
      conn =
        conn
        |> post(
          Routes.reset_password_path(conn, :create, %{reset_password: %{email: "email@email.com"}})
        )

      assert %{"success" => true} = json_response(conn, 200)["data"]

      assert_no_email_sent()
    end
  end
end
