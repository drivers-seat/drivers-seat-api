defmodule DriversSeatCoopWeb.AcceptedTermsControllerTest do
  use DriversSeatCoopWeb.ConnCase, async: true

  alias DriversSeatCoop.Legal.AcceptedTerms

  @invalid_attrs %{}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all accepted_terms", %{conn: conn} do
      user = Factory.create_user()
      user2 = Factory.create_user()

      %AcceptedTerms{id: accepted_terms_id} = Factory.create_accepted_terms(%{user_id: user.id})
      Factory.create_accepted_terms(%{user_id: user2.id})

      conn =
        TestHelpers.put_auth_header(conn, user)
        |> get(Routes.accepted_terms_path(conn, :index))

      assert [%{"id" => ^accepted_terms_id}] = json_response(conn, 200)["data"]
    end
  end

  describe "create accepted_terms" do
    test "renders accepted_terms when data is valid", %{conn: conn} do
      user = Factory.create_user()
      terms = Factory.create_terms()
      terms_id = terms.id

      valid_attrs = %{terms_id: terms_id}

      conn =
        TestHelpers.put_auth_header(conn, user)
        |> post(Routes.accepted_terms_path(conn, :create), accepted_terms: valid_attrs)

      assert %{"id" => id, "terms" => %{"id" => ^terms_id}} = json_response(conn, 201)["data"]

      conn = get(conn, Routes.accepted_terms_path(conn, :show, id))

      assert %{"accepted_at" => _, "terms" => %{"text" => _, "required_at" => _, "title" => _}} =
               json_response(conn, 200)["data"]
    end

    test "allows accepting terms multiple times", %{conn: conn} do
      user = Factory.create_user()

      %AcceptedTerms{
        accepted_at: accepted_at,
        id: accepted_terms_id,
        terms_id: terms_id
      } =
        Factory.create_accepted_terms(%{
          accepted_at: ~N[2022-03-20 11:11:11],
          user_id: user.id
        })

      accepted_at_str = NaiveDateTime.to_iso8601(accepted_at)

      valid_attrs = %{terms_id: terms_id}

      post(conn, Routes.accepted_terms_path(conn, :create), accepted_terms: valid_attrs)

      conn =
        TestHelpers.put_auth_header(conn, user)
        |> post(Routes.accepted_terms_path(conn, :create), accepted_terms: valid_attrs)

      assert %{
               "id" => ^accepted_terms_id,
               "accepted_at" => ^accepted_at_str,
               "terms" => %{
                 "id" => ^terms_id
               }
             } = json_response(conn, 201)["data"]

      conn = get(conn, Routes.accepted_terms_path(conn, :show, accepted_terms_id))

      assert %{
               "accepted_at" => ^accepted_at_str,
               "terms" => %{
                 "id" => ^terms_id,
                 "text" => _,
                 "required_at" => _,
                 "title" => _
               }
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.user_path(conn, :create), user: @invalid_attrs)
      assert json_response(conn, 422)
    end
  end
end
