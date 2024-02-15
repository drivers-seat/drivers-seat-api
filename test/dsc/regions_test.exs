defmodule DriversSeatCoop.RegionsTest do
  use DriversSeatCoop.DataCase

  alias DriversSeatCoop.Regions

  describe "states" do
    test "get_state_by_id works" do
      state_1 = Factory.create_state(1)
      _state_2 = Factory.create_state(2)

      actual_state_1 = Regions.get_state_by_id(1)

      assert actual_state_1 == state_1
    end

    test "get_state_by_id works when not found" do
      _state_1 = Factory.create_state(1)
      _state_2 = Factory.create_state(2)

      actual_state_1 = Regions.get_state_by_id(7)

      assert actual_state_1 == nil
    end

    test "get_state_by_id works when nil" do
      actual_state_1 = Regions.get_state_by_id(nil)
      assert actual_state_1 == nil
    end
  end

  describe "counties" do
    test "get_county_by_id works" do
      _state_1 = Factory.create_state(1)
      county_1 = Factory.create_county(10, 1)
      county_2 = Factory.create_county(11, 1)

      actual_county_1 = Regions.get_county_by_id(10)
      actual_county_2 = Regions.get_county_by_id(11)

      assert actual_county_1 == county_1
      assert actual_county_2 == county_2
    end

    test "get_state_by_id works when not found" do
      _state_1 = Factory.create_state(1)
      _county_1 = Factory.create_county(10, 1)
      _county_2 = Factory.create_county(11, 1)

      actual_county_1 = Regions.get_county_by_id(42)

      assert actual_county_1 == nil
    end

    test "get_state_by_id works when nil" do
      actual_county_1 = Regions.get_county_by_id(nil)

      assert actual_county_1 == nil
    end
  end

  describe "metro areas" do
    test "get_metro_area_by_id works" do
      metro_1 = Factory.create_metro_area(1)
      metro_2 = Factory.create_metro_area(2)

      actual_metro_area_1 = Regions.get_metro_area_by_id(metro_1.id)
      actual_metro_area_2 = Regions.get_metro_area_by_id(metro_2.id)

      assert actual_metro_area_1 == metro_1
      assert actual_metro_area_2 == metro_2
    end

    test "get_metro_area_by_id works when not found" do
      _metro_1 = Factory.create_metro_area(1)
      _metro_2 = Factory.create_metro_area(2)

      actual_metro_area_1 = Regions.get_metro_area_by_id(45)

      assert actual_metro_area_1 == nil
    end

    test "get_metro_area_by_id works when nil" do
      actual_metro_area_1 = Regions.get_metro_area_by_id(nil)

      assert actual_metro_area_1 == nil
    end

    test "query_metro_areas_hourly_pay_stat_coverage_percent filters lteq" do
      metro_1 =
        Factory.create_metro_area(1, %{hourly_pay_stat_coverage_percent: Decimal.from_float(0.2)})

      metro_2 =
        Factory.create_metro_area(2, %{hourly_pay_stat_coverage_percent: Decimal.from_float(0.4)})

      _metro_3 =
        Factory.create_metro_area(3, %{hourly_pay_stat_coverage_percent: Decimal.from_float(0.6)})

      actual_metros =
        Regions.query_metro_areas()
        |> Regions.query_metro_areas_hourly_pay_stat_coverage_percent(
          nil,
          Decimal.from_float(0.5)
        )
        |> Repo.all()

      assert 2 == Enum.count(actual_metros)
      assert metro_1 == Enum.find(actual_metros, fn m -> m.id == metro_1.id end)
      assert metro_2 == Enum.find(actual_metros, fn m -> m.id == metro_2.id end)

      actual_metros =
        Regions.query_metro_areas()
        |> Regions.query_metro_areas_hourly_pay_stat_coverage_percent(
          nil,
          Decimal.from_float(0.4)
        )
        |> Repo.all()

      assert 2 == Enum.count(actual_metros)
      assert metro_1 == Enum.find(actual_metros, fn m -> m.id == metro_1.id end)
      assert metro_2 == Enum.find(actual_metros, fn m -> m.id == metro_2.id end)
    end

    test "query_metro_areas_hourly_pay_stat_coverage_percent filters gteq" do
      _metro_1 =
        Factory.create_metro_area(1, %{hourly_pay_stat_coverage_percent: Decimal.from_float(0.2)})

      metro_2 =
        Factory.create_metro_area(2, %{hourly_pay_stat_coverage_percent: Decimal.from_float(0.4)})

      metro_3 =
        Factory.create_metro_area(3, %{hourly_pay_stat_coverage_percent: Decimal.from_float(0.6)})

      actual_metros =
        Regions.query_metro_areas()
        |> Regions.query_metro_areas_hourly_pay_stat_coverage_percent(
          Decimal.from_float(0.3),
          nil
        )
        |> Repo.all()

      assert 2 == Enum.count(actual_metros)
      assert metro_2 == Enum.find(actual_metros, fn m -> m.id == metro_2.id end)
      assert metro_3 == Enum.find(actual_metros, fn m -> m.id == metro_3.id end)

      actual_metros =
        Regions.query_metro_areas()
        |> Regions.query_metro_areas_hourly_pay_stat_coverage_percent(
          Decimal.from_float(0.4),
          nil
        )
        |> Repo.all()

      assert 2 == Enum.count(actual_metros)
      assert metro_2 == Enum.find(actual_metros, fn m -> m.id == metro_2.id end)
      assert metro_3 == Enum.find(actual_metros, fn m -> m.id == metro_3.id end)
    end

    test "query_metro_areas_hourly_pay_stat_coverage_percent filters range" do
      _metro_1 =
        Factory.create_metro_area(1, %{hourly_pay_stat_coverage_percent: Decimal.from_float(0.2)})

      metro_2 =
        Factory.create_metro_area(2, %{hourly_pay_stat_coverage_percent: Decimal.from_float(0.4)})

      metro_3 =
        Factory.create_metro_area(3, %{hourly_pay_stat_coverage_percent: Decimal.from_float(0.6)})

      _metro_4 =
        Factory.create_metro_area(4, %{hourly_pay_stat_coverage_percent: Decimal.from_float(0.8)})

      actual_metros =
        Regions.query_metro_areas()
        |> Regions.query_metro_areas_hourly_pay_stat_coverage_percent(
          Decimal.from_float(0.3),
          Decimal.from_float(0.7)
        )
        |> Repo.all()

      assert 2 == Enum.count(actual_metros)
      assert metro_2 == Enum.find(actual_metros, fn m -> m.id == metro_2.id end)
      assert metro_3 == Enum.find(actual_metros, fn m -> m.id == metro_3.id end)

      actual_metros =
        Regions.query_metro_areas()
        |> Regions.query_metro_areas_hourly_pay_stat_coverage_percent(
          Decimal.from_float(0.4),
          Decimal.from_float(0.6)
        )
        |> Repo.all()

      assert 2 == Enum.count(actual_metros)
      assert metro_2 == Enum.find(actual_metros, fn m -> m.id == metro_2.id end)
      assert metro_3 == Enum.find(actual_metros, fn m -> m.id == metro_3.id end)
    end
  end

  describe "postal_codes" do
    test "get_postal_code works" do
      state_1 = Factory.create_state(1)
      county_10 = Factory.create_county(10, state_1.id)
      metro_100 = Factory.create_metro_area(100)

      postal_97209 =
        Factory.create_postal_code(97_209, "97209", county_10.id, state_1.id, metro_100.id)

      postal_97210 = Factory.create_postal_code(97_210, "97210", county_10.id, state_1.id)

      actual_postal_97209 = Regions.get_postal_code("97209", false)
      actual_postal_97210 = Regions.get_postal_code("97210", false)

      assert postal_97209 == actual_postal_97209
      assert postal_97210 == actual_postal_97210
    end

    test "get_postal_code works include metro" do
      state_1 = Factory.create_state(1)
      county_10 = Factory.create_county(10, state_1.id)
      metro_100 = Factory.create_metro_area(100)

      postal_97209 =
        Factory.create_postal_code(97_209, "97209", county_10.id, state_1.id, metro_100.id)

      postal_97210 = Factory.create_postal_code(97_210, "97210", county_10.id, state_1.id)

      actual_postal_97209 = Regions.get_postal_code("97209", true)
      actual_postal_97210 = Regions.get_postal_code("97210", true)

      assert Map.put(postal_97209, :metro_area, metro_100) == actual_postal_97209
      assert Map.put(postal_97210, :metro_area, nil) == actual_postal_97210
    end
  end

  describe "get_metro_area_for_user" do
    setup do
      state_1 = Factory.create_state(1)
      county_10 = Factory.create_county(10, state_1.id)
      metro_100 = Factory.create_metro_area(100)
      metro_101 = Factory.create_metro_area(101)
      Factory.create_postal_code(97_209, "97209", county_10.id, state_1.id, metro_100.id)
      Factory.create_postal_code(97_210, "97210", county_10.id, state_1.id, metro_101.id)
      Factory.create_postal_code(97_211, "97211", county_10.id, state_1.id)
      :ok
    end

    test "favors user postal code when supplied and has metro" do
      user =
        Factory.create_user(%{
          postal_code: "97209",
          postal_code_argyle: "97210"
        })

      assert user.postal_code == "97209"
      assert user.postal_code_argyle == "97210"

      actual_metro = Regions.get_metro_area_for_user(user)
      expected_metro = Regions.get_metro_area_by_id(100)

      assert actual_metro == expected_metro
    end

    test "favors argyle postal code when both supplied and user postal code does not match" do
      user =
        Factory.create_user(%{
          postal_code: "33176",
          postal_code_argyle: "97210"
        })

      assert user.postal_code == "33176"
      assert user.postal_code_argyle == "97210"

      actual_metro = Regions.get_metro_area_for_user(user)
      expected_metro = Regions.get_metro_area_by_id(101)

      assert actual_metro == expected_metro
    end

    test "favors argyle postal code when both supplied and user postal code matches but does not have metro" do
      user =
        Factory.create_user(%{
          postal_code: "97211",
          postal_code_argyle: "97210"
        })

      assert user.postal_code == "97211"
      assert user.postal_code_argyle == "97210"

      actual_metro = Regions.get_metro_area_for_user(user)
      expected_metro = Regions.get_metro_area_by_id(101)

      assert actual_metro == expected_metro
    end

    test "works with empty missing data" do
      user_1 =
        Factory.create_user(%{
          postal_code: nil,
          postal_code_argyle: "97210"
        })

      assert user_1.postal_code == nil
      assert user_1.postal_code_argyle == "97210"

      user_2 =
        Factory.create_user(%{
          postal_code: "97210",
          postal_code_argyle: nil
        })

      assert user_2.postal_code == "97210"
      assert user_2.postal_code_argyle == nil

      user_3 =
        Factory.create_user(%{
          postal_code: nil,
          postal_code_argyle: nil
        })

      assert user_3.postal_code == nil
      assert user_3.postal_code_argyle == nil

      actual_metro_1 = Regions.get_metro_area_for_user(user_1)
      actual_metro_2 = Regions.get_metro_area_for_user(user_2)
      actual_metro_3 = Regions.get_metro_area_for_user(user_3)

      expected_metro = Regions.get_metro_area_by_id(101)

      assert actual_metro_1 == expected_metro
      assert actual_metro_2 == expected_metro
      assert actual_metro_3 == nil
    end
  end
end
