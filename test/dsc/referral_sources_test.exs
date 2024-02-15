defmodule DriversSeatCoop.ReferralSourcesTest do
  use DriversSeatCoop.DataCase
  alias DriversSeatCoop.ReferralSources

  @referral_type_valid :app_invite_menu
  @referral_code_1 "ABCD"
  @referral_code_2 "EFGH"
  @referral_code_3 "IJKL"

  describe "referral_sources" do
    test "get_referral_source gets a user-associated referral source" do
      user = Factory.create_user()

      {:ok, expected} =
        ReferralSources.create_referral_source(%{
          user_id: user.id,
          referral_type: @referral_type_valid,
          referral_code: @referral_code_1
        })

      actual = ReferralSources.get_referral_source(expected.referral_code)

      assert expected == actual
    end

    test "get_referral_source gets a non user-associated referral source" do
      {:ok, expected} =
        ReferralSources.create_referral_source(%{
          referral_type: @referral_type_valid,
          referral_code: @referral_code_1
        })

      actual = ReferralSources.get_referral_source(expected.referral_code)

      assert expected == actual
    end

    test "get_referral_source gets an inactive referral source" do
      {:ok, expected} =
        ReferralSources.create_referral_source(%{
          referral_type: @referral_type_valid,
          referral_code: @referral_code_1,
          is_active: false
        })

      actual = ReferralSources.get_referral_source(expected.referral_code)

      assert expected == actual
    end

    test "get_referral_source is case insensitive" do
      user = Factory.create_user()

      {:ok, expected} =
        ReferralSources.create_or_generate_referral_source(@referral_type_valid, user.id)

      actual_1 = ReferralSources.get_referral_source(String.downcase(expected.referral_code))
      actual_2 = ReferralSources.get_referral_source(String.upcase(expected.referral_code))

      assert actual_1 == expected
      assert actual_2 == expected
    end

    test "list_referral_sources returns referral sources for the user" do
      user_1 = Factory.create_user()

      {:ok, expected_1} =
        ReferralSources.create_referral_source(%{
          user_id: user_1.id,
          referral_type: @referral_type_valid,
          referral_code: @referral_code_1
        })

      user_2 = Factory.create_user()

      {:ok, expected_2} =
        ReferralSources.create_referral_source(%{
          user_id: user_2.id,
          referral_type: @referral_type_valid,
          referral_code: @referral_code_2
        })

      {:ok, _ref_source_3} =
        ReferralSources.create_referral_source(%{
          referral_type: @referral_type_valid,
          referral_code: @referral_code_3
        })

      actual_1 = ReferralSources.list_referral_sources(user_1.id)
      actual_2 = ReferralSources.list_referral_sources(user_2.id)

      assert actual_1 == [expected_1]
      assert actual_2 == [expected_2]
    end

    test "create_or_generate_referral_source accepts valid referral type" do
      user = Factory.create_user()

      {:ok, expected_referral_source} =
        ReferralSources.create_or_generate_referral_source(@referral_type_valid, user.id)

      assert expected_referral_source.user_id == user.id
      assert expected_referral_source.referral_type == @referral_type_valid
      assert expected_referral_source.is_active
    end

    test "create_or_generate_referral_source fails for invalid user_id" do
      assert {:error, cs = %Ecto.Changeset{}} =
               ReferralSources.create_or_generate_referral_source(
                 @referral_type_valid,
                 109
               )

      assert %{user: ["does not exist"]} == errors_on(cs)
    end

    test "create_or_generate_referral_source/1 uses existing code" do
      {:ok, expected} = ReferralSources.create_or_generate_referral_source(@referral_type_valid)

      {:ok, actual} = ReferralSources.create_or_generate_referral_source(@referral_type_valid)

      assert expected == actual
    end

    test "create_or_generate_referral_source/2 uses existing code" do
      user = Factory.create_user()

      {:ok, expected} =
        ReferralSources.create_or_generate_referral_source(@referral_type_valid, user.id)

      {:ok, actual} =
        ReferralSources.create_or_generate_referral_source(@referral_type_valid, user.id)

      assert expected == actual
    end

    test "create_referral_source fails on duplicate code" do
      {:ok, _} =
        ReferralSources.create_referral_source(%{
          referral_type: @referral_type_valid,
          referral_code: @referral_code_1
        })

      assert {:error, cs = %Ecto.Changeset{}} =
               ReferralSources.create_referral_source(%{
                 referral_type: @referral_type_valid,
                 referral_code: @referral_code_1
               })

      assert %{referral_code: ["Referral Code Already Exists"]} == errors_on(cs)

      assert {:error, cs = %Ecto.Changeset{}} =
               ReferralSources.create_referral_source(%{
                 referral_type: @referral_type_valid,
                 referral_code: String.downcase(@referral_code_1)
               })

      assert %{referral_code: ["Referral Code Already Exists"]} == errors_on(cs)

      assert {:error, cs = %Ecto.Changeset{}} =
               ReferralSources.create_referral_source(%{
                 referral_type: @referral_type_valid,
                 referral_code: String.upcase(@referral_code_1)
               })

      assert %{referral_code: ["Referral Code Already Exists"]} == errors_on(cs)
    end
  end
end
