defmodule DriversSeatCoopWeb.ReferralSourceControllerTest do
  use DriversSeatCoopWeb.ConnCase, async: true
  alias DriversSeatCoop.ReferralSources

  @referral_type_valid_1 "app_invite_menu"
  @referral_type_valid_2 "app_invite_hourly_pay_analytics"
  @referral_type_invalid "bad"
  @referral_code_1 "8Y21"

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists referral sources for calling user" do
    end
  end

  describe "lookup" do
    test "returns referral source by code - referral source tied to user", %{conn: conn} do
      user = Factory.create_user()

      {:ok, referral_source} =
        ReferralSources.create_or_generate_referral_source(@referral_type_valid_1, user.id)

      conn = get(conn, Routes.referral_source_path(conn, :lookup, referral_source.referral_code))

      assert json_response(conn, 200)["data"]
    end

    test "returns referral source by code - referral source not tied to a user", %{conn: conn} do
      {:ok, referral_source} =
        ReferralSources.create_referral_source(%{
          referral_type: @referral_type_valid_2,
          referral_code: @referral_code_1
        })

      conn = get(conn, Routes.referral_source_path(conn, :lookup, referral_source.referral_code))

      assert json_response(conn, 200)["data"]
    end

    test "returns not found when not found", %{conn: conn} do
      conn = get(conn, Routes.referral_source_path(conn, :lookup, @referral_code_1))

      assert json_response(conn, 404)
    end
  end

  describe "show" do
    test "requires authentication", %{conn: conn} do
      user = Factory.create_user()

      {:ok, _referral_source} =
        ReferralSources.create_or_generate_referral_source(@referral_type_valid_1, user.id)

      conn =
        get(conn, Routes.referral_source_path(conn, :show, user.id), %{
          referral_type: @referral_type_valid_1
        })

      assert json_response(conn, 401)
    end

    test "returns existing referral source associted calling user", %{conn: conn} do
      user = Factory.create_user()

      {:ok, referral_source} =
        ReferralSources.create_or_generate_referral_source(@referral_type_valid_2, user.id)

      conn =
        conn
        |> TestHelpers.put_auth_header(user)
        |> get(Routes.referral_source_path(conn, :show, user.id), %{
          referral_type: @referral_type_valid_2
        })

      assert %{
               "referral_type" => Atom.to_string(referral_source.referral_type),
               "referral_code" => referral_source.referral_code,
               "is_active" => referral_source.is_active
             } == json_response(conn, 200)["data"]
    end

    test "creates new referral source for user when one does not exist", %{conn: conn} do
      user = Factory.create_user()

      conn =
        conn
        |> TestHelpers.put_auth_header(user)
        |> get(Routes.referral_source_path(conn, :show, user.id), %{
          referral_type: @referral_type_valid_1
        })

      actual = json_response(conn, 200)["data"]

      assert !is_nil(actual)
      assert actual["referral_type"] == @referral_type_valid_1
      assert String.length(actual["referral_code"]) == 4
      assert actual["is_active"] == true

      actual_referral_source = ReferralSources.get_referral_source(actual["referral_code"])

      assert actual_referral_source.user_id == user.id
    end

    test "fails on invalid referral type", %{conn: conn} do
      user = Factory.create_user()

      conn =
        conn
        |> TestHelpers.put_auth_header(user)
        |> get(Routes.referral_source_path(conn, :show, user.id), %{
          referral_type: @referral_type_invalid
        })

      assert json_response(conn, 422)["errors"]
    end
  end
end
