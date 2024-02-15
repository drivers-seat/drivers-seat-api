defmodule DriversSeatCoopWeb.LatestTermsPlugTest do
  use DriversSeatCoopWeb.ConnCase, async: true

  alias DriversSeatCoop.Legal.Terms
  alias DriversSeatCoopWeb.{AuthenticationPlug, LatestTermsPlug}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "current" do
    test "does not return error if there are no current terms", %{conn: conn} do
      user = Factory.create_user()

      conn =
        TestHelpers.put_auth_header(conn, user)
        |> AuthenticationPlug.call([])
        |> LatestTermsPlug.call([])
        |> get(Routes.session_path(conn, :index))

      assert json_response(conn, 200)
    end

    test "does not return error if user has agreed to current terms", %{conn: conn} do
      user = Factory.create_user()
      required_at = ~N[2020-01-01 00:00:00]
      %Terms{id: terms_id} = Factory.create_terms(%{required_at: required_at})
      Factory.create_accepted_terms(%{user_id: user.id, terms_id: terms_id})

      conn =
        TestHelpers.put_auth_header(conn, user)
        |> AuthenticationPlug.call([])
        |> LatestTermsPlug.call([])
        |> get(Routes.session_path(conn, :index))

      assert json_response(conn, 200)
    end

    test "returns error if there are current terms and user has not accepted", %{conn: conn} do
      user = Factory.create_user()
      required_at = ~N[2020-01-01 00:00:00]
      %Terms{id: terms_id} = Factory.create_terms(%{required_at: required_at})

      conn =
        TestHelpers.put_auth_header(conn, user)
        |> AuthenticationPlug.call([])
        |> LatestTermsPlug.call([])
        |> get(Routes.session_path(conn, :index))

      assert %{
               "errors" => %{
                 "detail" =>
                   "Unavailable For Legal Reasons. Please agree to the updated terms of service.",
                 "terms" => %{
                   "id" => ^terms_id,
                   "title" => _,
                   "text" => _
                 }
               }
             } = json_response(conn, 451)
    end
  end
end
