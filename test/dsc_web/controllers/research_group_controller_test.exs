defmodule DriversSeatCoopWeb.ResearchGroupControllerTest do
  use DriversSeatCoopWeb.ConnCase

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "lookup" do
    test "returns research_group with valid code", %{conn: conn} do
      user = Factory.create_user()
      rg = Factory.create_research_group()

      conn =
        TestHelpers.put_auth_header(conn, user)
        |> get(Routes.research_group_path(conn, :lookup, rg.code))

      assert json_response(conn, 200)["data"]
    end

    test "returns 404 with invalid code", %{conn: conn} do
      user = Factory.create_user()

      conn =
        TestHelpers.put_auth_header(conn, user)
        |> get(Routes.research_group_path(conn, :lookup, "bad code"))

      assert json_response(conn, 404)
    end
  end
end
