defmodule DriversSeatCoopWeb.HelpControllerTest do
  use DriversSeatCoopWeb.ConnCase

  import Swoosh.TestAssertions

  @subject "some subject"
  @message "some_description"
  @name "name"
  @email "some_email@test.com"
  @help_email_inbox "HELP_EMAIL_INBOX@TEST.COM"

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "create help request" do
    test "sends help request email for non-authenticated user", %{conn: conn} do
      # user = Factory.create_user(%{email: "test@rokkincat.com"})

      conn =
        conn
        |> post(
          Routes.help_path(conn, :create, %{
            email: @email,
            name: @name,
            subject: @subject,
            message: @message
          })
        )

      assert response(conn, 204)

      assert_email_sent(
        subject: "New Help Request - #{@subject}",
        to: {"", @help_email_inbox}
      )
    end

    test "sends help request email for authenticated user", %{conn: conn} do
      user = Factory.create_user(%{email: "test@driversseat.co"})

      conn =
        conn
        |> TestHelpers.put_auth_header(user)
        |> post(
          Routes.help_path(conn, :create, %{
            email: @email,
            name: @name,
            subject: @subject,
            message: @message
          })
        )

      assert response(conn, 204)

      assert_email_sent(
        subject: "New Help Request - #{@subject}",
        to: {"", @help_email_inbox}
      )
    end

    test "fails to send when missing email", %{conn: conn} do
      conn =
        conn
        |> post(
          Routes.help_path(conn, :create, %{
            name: @name,
            subject: @subject,
            message: @message
          })
        )

      assert response(conn, 422)
    end

    test "fails to send when missing subject", %{conn: conn} do
      conn =
        conn
        |> post(
          Routes.help_path(conn, :create, %{
            name: @name,
            email: @email,
            message: @message
          })
        )

      assert response(conn, 422)
    end

    test "fails to send when missing message", %{conn: conn} do
      conn =
        conn
        |> post(
          Routes.help_path(conn, :create, %{
            name: @name,
            email: @email,
            subject: @subject
          })
        )

      assert response(conn, 422)
    end
  end
end
