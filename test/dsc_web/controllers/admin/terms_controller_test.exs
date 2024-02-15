defmodule DriversSeatCoopWeb.Admin.TermsControllerTest do
  use DriversSeatCoopWeb.ConnCase

  @create_attrs %{required_at: ~N[2010-04-17 14:00:00], text: "some text", title: "some title"}
  @update_attrs %{
    required_at: ~N[2011-05-18 15:01:01],
    text: "some updated text",
    title: "some updated title"
  }
  @invalid_attrs %{required_at: nil, text: nil, title: nil}

  defp admin_session(state) do
    admin = Factory.create_admin_user()
    conn = TestHelpers.put_admin_session(state.conn, admin)

    {:ok, conn: conn, admin: admin}
  end

  describe "index" do
    setup [:admin_session]

    test "lists all terms", %{conn: conn} do
      conn = get(conn, Routes.admin_terms_path(conn, :index))
      assert html_response(conn, 200) =~ "Terms"
    end
  end

  describe "new terms" do
    setup [:admin_session]

    test "renders form", %{conn: conn} do
      conn = get(conn, Routes.admin_terms_path(conn, :new))
      assert html_response(conn, 200) =~ "New Terms"
    end
  end

  describe "create terms" do
    setup [:admin_session]

    test "redirects to show when data is valid", %{conn: conn} do
      conn = post conn, Routes.admin_terms_path(conn, :create), terms: @create_attrs

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.admin_terms_path(conn, :show, id)

      conn = get(conn, Routes.admin_terms_path(conn, :show, id))
      assert html_response(conn, 200) =~ "Terms Details"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, Routes.admin_terms_path(conn, :create), terms: @invalid_attrs
      assert html_response(conn, 200) =~ "New Terms"
    end
  end

  describe "edit terms" do
    setup [:admin_session, :create_terms]

    test "renders form for editing chosen terms", %{conn: conn, terms: terms} do
      conn = get(conn, Routes.admin_terms_path(conn, :edit, terms))
      assert html_response(conn, 200) =~ "Edit Terms"
    end
  end

  describe "update terms" do
    setup [:admin_session, :create_terms]

    test "redirects when data is valid", %{conn: conn, terms: terms} do
      conn = put conn, Routes.admin_terms_path(conn, :update, terms), terms: @update_attrs
      assert redirected_to(conn) == Routes.admin_terms_path(conn, :show, terms)

      conn = get(conn, Routes.admin_terms_path(conn, :show, terms))
      assert html_response(conn, 200) =~ "some updated text"
    end

    test "renders errors when data is invalid", %{conn: conn, terms: terms} do
      conn = put conn, Routes.admin_terms_path(conn, :update, terms), terms: @invalid_attrs
      assert html_response(conn, 200) =~ "Edit Terms"
    end
  end

  describe "delete terms" do
    setup [:admin_session, :create_terms]

    test "deletes chosen terms", %{conn: conn, terms: terms} do
      conn = delete(conn, Routes.admin_terms_path(conn, :delete, terms))
      assert redirected_to(conn) == Routes.admin_terms_path(conn, :index)

      assert_error_sent 404, fn ->
        get(conn, Routes.admin_terms_path(conn, :show, terms))
      end
    end
  end

  defp create_terms(%{admin: admin}) do
    terms = Factory.create_terms(%{user_id: admin.id})
    {:ok, terms: terms}
  end
end
