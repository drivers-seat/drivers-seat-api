defmodule DriversSeatCoopWeb.TermsControllerTest do
  use DriversSeatCoopWeb.ConnCase, async: true

  alias DriversSeatCoop.Legal.Terms

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "show" do
    test "shows terms", %{conn: conn} do
      user = Factory.create_user()

      %Terms{id: terms_id} = Factory.create_terms()

      conn =
        TestHelpers.put_auth_header(conn, user)
        |> get(Routes.terms_path(conn, :show, terms_id))

      assert %{"id" => ^terms_id, "text" => _, "required_at" => _} =
               json_response(conn, 200)["data"]
    end
  end

  describe "current" do
    test "shows currently required terms with accepted_terms when accepted", %{conn: conn} do
      user = Factory.create_user()
      required_at = ~N[2020-01-01 00:00:00]

      future_required_at =
        NaiveDateTime.utc_now()
        |> NaiveDateTime.add(1200, :second)

      %Terms{id: terms_id} = Factory.create_terms(%{required_at: required_at})
      %Terms{id: future_terms_id} = Factory.create_terms(%{required_at: future_required_at})

      Factory.create_accepted_terms(%{user_id: user.id, terms_id: terms_id})

      conn =
        TestHelpers.put_auth_header(conn, user)
        |> get(Routes.terms_path(conn, :current))

      assert %{
               "current_terms" => %{
                 "id" => ^terms_id,
                 "text" => _,
                 "required_at" => _
               },
               "current_accepted_terms" => %{},
               "future_terms" => %{
                 "id" => ^future_terms_id,
                 "text" => _,
                 "required_at" => _
               },
               "future_accepted_terms" => nil
             } = json_response(conn, 200)["data"]
    end

    test "shows currently required terms with null accepted_terms if not accepted", %{conn: conn} do
      user = Factory.create_user()
      required_at = ~N[2020-01-01 00:00:00]

      %Terms{id: terms_id} = Factory.create_terms(%{required_at: required_at})

      conn =
        TestHelpers.put_auth_header(conn, user)
        |> get(Routes.terms_path(conn, :current))

      assert %{
               "current_terms" => %{
                 "id" => ^terms_id,
                 "text" => _,
                 "required_at" => _
               },
               "current_accepted_terms" => nil,
               "future_terms" => nil,
               "future_accepted_terms" => nil
             } = json_response(conn, 200)["data"]
    end

    test "shows nil if there are no currently required terms", %{conn: conn} do
      user = Factory.create_user()

      conn =
        TestHelpers.put_auth_header(conn, user)
        |> get(Routes.terms_path(conn, :current))

      assert json_response(conn, 200)["data"] == %{
               "current_terms" => nil,
               "current_accepted_terms" => nil,
               "future_terms" => nil,
               "future_accepted_terms" => nil
             }
    end
  end
end
