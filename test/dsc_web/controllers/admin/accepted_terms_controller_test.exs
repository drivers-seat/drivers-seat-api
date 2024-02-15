defmodule DriversSeatCoopWeb.Admin.AcceptedTermsControllerTest do
  use DriversSeatCoopWeb.ConnCase

  @update_attrs %{accepted_at: ~N[2011-05-18 15:01:01]}
  @invalid_attrs %{accepted_at: nil}

  defp admin_session(state) do
    admin = Factory.create_admin_user()
    conn = TestHelpers.put_admin_session(state.conn, admin)

    {:ok, conn: conn, admin: admin}
  end

  describe "index" do
    setup [:admin_session]

    test "lists all accepted_terms", %{conn: conn} do
      conn = get(conn, Routes.admin_accepted_terms_path(conn, :index))
      assert html_response(conn, 200) =~ "Accepted terms"
    end
  end

  describe "new accepted_terms" do
    setup [:admin_session]

    test "renders form", %{conn: conn} do
      conn = get(conn, Routes.admin_accepted_terms_path(conn, :new))
      assert html_response(conn, 200) =~ "New Accepted terms"
    end
  end

  describe "create accepted_terms" do
    setup [:admin_session]

    test "renders errors when data is invalid", %{conn: conn} do
      conn =
        post conn, Routes.admin_accepted_terms_path(conn, :create), accepted_terms: @invalid_attrs

      assert html_response(conn, 200) =~ "New Accepted terms"
    end
  end

  describe "edit accepted_terms" do
    setup [:admin_session, :create_accepted_terms]

    test "renders form for editing chosen accepted_terms", %{
      conn: conn,
      accepted_terms: accepted_terms
    } do
      conn = get(conn, Routes.admin_accepted_terms_path(conn, :edit, accepted_terms))
      assert html_response(conn, 200) =~ "Edit Accepted terms"
    end
  end

  describe "update accepted_terms" do
    setup [:admin_session, :create_accepted_terms]

    test "redirects when data is valid", %{conn: conn, accepted_terms: accepted_terms} do
      conn =
        put conn, Routes.admin_accepted_terms_path(conn, :update, accepted_terms),
          accepted_terms: @update_attrs

      assert redirected_to(conn) == Routes.admin_accepted_terms_path(conn, :show, accepted_terms)

      conn = get(conn, Routes.admin_accepted_terms_path(conn, :show, accepted_terms))
      assert html_response(conn, 200)
    end

    test "renders errors when data is invalid", %{conn: conn, accepted_terms: accepted_terms} do
      conn =
        put conn, Routes.admin_accepted_terms_path(conn, :update, accepted_terms),
          accepted_terms: @invalid_attrs

      assert html_response(conn, 200) =~ "Edit Accepted terms"
    end
  end

  describe "delete accepted_terms" do
    setup [:admin_session, :create_accepted_terms]

    test "deletes chosen accepted_terms", %{conn: conn, accepted_terms: accepted_terms} do
      conn = delete(conn, Routes.admin_accepted_terms_path(conn, :delete, accepted_terms))
      assert redirected_to(conn) == Routes.admin_accepted_terms_path(conn, :index)

      assert_error_sent 404, fn ->
        get(conn, Routes.admin_accepted_terms_path(conn, :show, accepted_terms))
      end
    end
  end

  defp create_accepted_terms(_) do
    accepted_terms = Factory.create_accepted_terms()
    {:ok, accepted_terms: accepted_terms}
  end
end
