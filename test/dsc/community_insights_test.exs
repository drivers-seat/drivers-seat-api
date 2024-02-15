defmodule DriversSeatCoop.CommunityInsightsTest do
  use DriversSeatCoop.DataCase, async: true

  alias DriversSeatCoop.Accounts
  alias DriversSeatCoop.CommunityInsights
  alias DriversSeatCoop.Driving
  alias DriversSeatCoop.Employers
  alias DriversSeatCoop.Repo

  setup do
    # create 3 metro areas
    metro_areas = for m <- 1..3, do: Factory.create_metro_area(m)

    # create 2 employees in each  metro area
    users =
      for m <- metro_areas,
          _ <- 1..2,
          do:
            Factory.create_user(
              %{
                timezone: "America/Los_Angeles"
              },
              %{
                metro_area_id: m.id
              }
            )

    # create 5 employers
    employers = for _ <- 1..5, do: Employers.get_or_create_employer(Ecto.UUID.generate())

    # create 2 service classes
    service_classes =
      for _ <- 1..2, do: Employers.get_or_create_service_class(Ecto.UUID.generate())

    # Service Class 0 has Employer 0, 1, 2
    # Service Class 1 has Employer 2, 3, 4
    service_class_id = Enum.at(service_classes, 0).id

    employer_service_classes =
      employers
      |> Enum.take(3)
      |> Enum.map(fn e ->
        Employers.get_or_create_employer_service_class(service_class_id, e.id)
      end)

    service_class_id = Enum.at(service_classes, 1).id

    employer_service_classes =
      employer_service_classes ++
        (employers
         |> Enum.take(-3)
         |> Enum.map(fn e ->
           Employers.get_or_create_employer_service_class(service_class_id, e.id)
         end))

    {:ok,
     %{
       users: users,
       employers: employers,
       service_classes: service_classes,
       employer_service_classes: employer_service_classes,
       metro_areas: metro_areas
     }}
  end

  describe "Time windows" do
    test "Stats weeks always start on Sunday" do
    end

    test "Get Weeks in Scope has 16 weeks" do
    end

    test "Is Current week is correct" do
    end
  end

  describe "Calc Community Insights Pay Stats" do
    test "excludes deleted activities", state do
      user = Enum.at(state.users, 0)
      employer = Enum.at(state.employers, 0)
      service_class = Enum.at(state.service_classes, 0)

      employer_service_class =
        state.employer_service_classes
        |> Enum.find(fn x ->
          x.employer_id == employer.id and
            x.service_class_id == service_class.id
        end)

      accept_time = NaiveDateTime.new!(~D[2023-12-01], ~T[01:45:00])
      start_time = NaiveDateTime.new!(~D[2023-12-01], ~T[02:15:00])
      end_time = NaiveDateTime.new!(~D[2023-12-01], ~T[03:15:00])

      activity =
        Factory.create_activity(
          user,
          employer,
          service_class,
          start_time,
          end_time,
          100.00,
          15.00,
          5,
          accept_time
        )

      insights_data =
        CommunityInsights.calculate_avg_hr_pay_stats_for_metro_week(
          ~D[2023-11-26],
          user.metro_area_id,
          1,
          1
        )

      assert insights_data != nil
      assert Enum.count(insights_data) == 3

      assert Enum.all?(insights_data, fn x ->
               x.employer_service_class_id == employer_service_class.id
             end)

      Driving.delete_activities(activity.activity_id)

      insights_data =
        CommunityInsights.calculate_avg_hr_pay_stats_for_metro_week(
          ~D[2023-11-26],
          user.metro_area_id,
          1,
          1
        )

      assert insights_data == []
    end

    test "excludes deleted users", state do
      user = Enum.at(state.users, 0)

      employer = Enum.at(state.employers, 0)
      service_class = Enum.at(state.service_classes, 0)

      employer_service_class =
        state.employer_service_classes
        |> Enum.find(fn x ->
          x.employer_id == employer.id and
            x.service_class_id == service_class.id
        end)

      accept_time = NaiveDateTime.new!(~D[2023-12-01], ~T[01:45:00])
      start_time = NaiveDateTime.new!(~D[2023-12-01], ~T[02:15:00])
      end_time = NaiveDateTime.new!(~D[2023-12-01], ~T[03:15:00])

      Factory.create_activity(
        user,
        employer,
        service_class,
        start_time,
        end_time,
        100.00,
        15.00,
        5,
        accept_time
      )

      insights_data =
        CommunityInsights.calculate_avg_hr_pay_stats_for_metro_week(
          ~D[2023-11-26],
          user.metro_area_id,
          1,
          1
        )

      assert insights_data != nil
      assert Enum.count(insights_data) == 3

      assert Enum.all?(insights_data, fn x ->
               x.employer_service_class_id == employer_service_class.id
             end)

      Accounts.delete_user(user)

      insights_data =
        CommunityInsights.calculate_avg_hr_pay_stats_for_metro_week(
          ~D[2023-11-26],
          user.metro_area_id,
          1,
          1
        )

      assert insights_data == []
    end

    test "excludes non-prod users", state do
      user = Enum.at(state.users, 0)
      employer = Enum.at(state.employers, 0)
      service_class = Enum.at(state.service_classes, 0)

      employer_service_class =
        state.employer_service_classes
        |> Enum.find(fn x ->
          x.employer_id == employer.id and
            x.service_class_id == service_class.id
        end)

      accept_time = NaiveDateTime.new!(~D[2023-12-01], ~T[01:45:00])
      start_time = NaiveDateTime.new!(~D[2023-12-01], ~T[02:15:00])
      end_time = NaiveDateTime.new!(~D[2023-12-01], ~T[03:15:00])

      Factory.create_activity(
        user,
        employer,
        service_class,
        start_time,
        end_time,
        100.00,
        15.00,
        5,
        accept_time
      )

      insights_data =
        CommunityInsights.calculate_avg_hr_pay_stats_for_metro_week(
          ~D[2023-11-26],
          user.metro_area_id,
          1,
          1
        )

      assert insights_data != nil
      assert Enum.count(insights_data) == 3

      assert Enum.all?(insights_data, fn x ->
               x.employer_service_class_id == employer_service_class.id
             end)

      Accounts.update_user(user, %{email: "#{Ecto.UUID.generate()}@driversseat.co"})

      insights_data =
        CommunityInsights.calculate_avg_hr_pay_stats_for_metro_week(
          ~D[2023-11-26],
          user.metro_area_id,
          1,
          1
        )

      assert insights_data == []
    end

    test "buckets time properly", state do
      user = Enum.at(state.users, 0)
      employer = Enum.at(state.employers, 0)
      service_class = Enum.at(state.service_classes, 0)

      employer_service_class =
        state.employer_service_classes
        |> Enum.find(fn x ->
          x.employer_id == employer.id and
            x.service_class_id == service_class.id
        end)

      accept_time = NaiveDateTime.new!(~D[2023-12-01], ~T[01:45:00])
      start_time = NaiveDateTime.new!(~D[2023-12-01], ~T[02:15:00])
      end_time = NaiveDateTime.new!(~D[2023-12-01], ~T[03:15:00])

      Factory.create_activity(
        user,
        employer,
        service_class,
        start_time,
        end_time,
        100.00,
        15.00,
        5,
        accept_time
      )

      insights_data =
        CommunityInsights.calculate_avg_hr_pay_stats_for_metro_week(
          ~D[2023-11-26],
          user.metro_area_id,
          1,
          1
        )

      assert insights_data != nil

      insights_data = Enum.sort_by(insights_data, fn x -> x.hour_local end)

      assert Enum.count(insights_data) == 3

      assert Enum.all?(insights_data, fn x ->
               x.employer_service_class_id == employer_service_class.id
             end)

      insights_hour_0 = Enum.at(insights_data, 0)
      insights_hour_1 = Enum.at(insights_data, 1)
      insights_hour_2 = Enum.at(insights_data, 2)

      assert Enum.all?(insights_data, fn x -> x.day_of_week == 5 end)
      assert Enum.all?(insights_data, fn x -> x.week_sample_first == ~D[2023-11-26] end)
      assert Enum.all?(insights_data, fn x -> x.week_sample_last == ~D[2023-11-26] end)
      assert Enum.all?(insights_data, fn x -> x.count_activities == 1 end)

      # 15/90 in the first hour
      assert insights_hour_0.hour_local == ~T[01:00:00]
      assert insights_hour_0.count_tasks == 1
      assert insights_hour_0.count_activities == 1
      assert insights_hour_0.duration_seconds == 15 * 60
      assert insights_hour_0.count_users == 1
      assert_in_delta(insights_hour_0.earnings_total_cents, 1_667, 1)
      assert insights_hour_0.distance_miles == Decimal.round(Decimal.from_float(2.5), 2)
      assert_in_delta(insights_hour_0.deduction_mileage_cents, 164, 1)
      assert_in_delta(insights_hour_0.earnings_avg_hr_cents, 6_668, 1)
      assert_in_delta(insights_hour_0.earnings_avg_hr_cents_with_mileage, 6_012, 1)

      # 60/90 in the first hour
      assert insights_hour_1.hour_local == ~T[02:00:00]
      assert insights_hour_1.count_tasks == 4
      assert insights_hour_1.count_activities == 1
      assert insights_hour_1.duration_seconds == 60 * 60
      assert insights_hour_1.count_users == 1
      assert_in_delta(insights_hour_1.earnings_total_cents, 6_667, 1)
      assert insights_hour_1.distance_miles == Decimal.round(Decimal.from_float(10.0), 2)
      assert_in_delta(insights_hour_1.deduction_mileage_cents, 655, 1)
      assert_in_delta(insights_hour_1.earnings_avg_hr_cents, 6_668, 1)
      assert_in_delta(insights_hour_1.earnings_avg_hr_cents_with_mileage, 6_012, 1)

      # 15/90 in the third hour
      assert insights_hour_2.hour_local == ~T[03:00:00]
      assert insights_hour_2.count_tasks == 1
      assert insights_hour_2.count_activities == 1
      assert insights_hour_2.duration_seconds == 15 * 60
      assert insights_hour_2.count_users == 1
      assert_in_delta(insights_hour_2.earnings_total_cents, 1_667, 1)
      assert insights_hour_2.distance_miles == Decimal.round(Decimal.from_float(2.5), 2)
      assert_in_delta(insights_hour_2.deduction_mileage_cents, 164, 1)
      assert_in_delta(insights_hour_2.earnings_avg_hr_cents, 6_668, 1)
      assert_in_delta(insights_hour_2.earnings_avg_hr_cents_with_mileage, 6_012, 1)
    end

    test "buckets by employer_service_class", state do
      user = Enum.at(state.users, 0)
      employer = Enum.at(state.employers, 2)

      service_class_0 = Enum.at(state.service_classes, 0)

      employer_service_class_0 =
        state.employer_service_classes
        |> Enum.find(fn x ->
          x.employer_id == employer.id and
            x.service_class_id == service_class_0.id
        end)

      service_class_1 = Enum.at(state.service_classes, 1)

      employer_service_class_1 =
        state.employer_service_classes
        |> Enum.find(fn x ->
          x.employer_id == employer.id and
            x.service_class_id == service_class_1.id
        end)

      accept_time = NaiveDateTime.new!(~D[2023-12-01], ~T[01:45:00])
      start_time = NaiveDateTime.new!(~D[2023-12-01], ~T[02:15:00])
      end_time = NaiveDateTime.new!(~D[2023-12-01], ~T[03:15:00])

      Factory.create_activity(
        user,
        employer,
        service_class_0,
        start_time,
        end_time,
        100.00,
        15.00,
        5,
        accept_time
      )

      Factory.create_activity(
        user,
        employer,
        service_class_1,
        start_time,
        end_time,
        50.00,
        30.00,
        10,
        accept_time
      )

      insights_data =
        CommunityInsights.calculate_avg_hr_pay_stats_for_metro_week(
          ~D[2023-11-26],
          user.metro_area_id,
          1,
          1
        )

      assert insights_data != nil
      assert Enum.count(insights_data) == 6

      # data from Employer Service Class 0
      insights_data_0 =
        insights_data
        |> Enum.filter(fn x -> x.employer_service_class_id == employer_service_class_0.id end)
        |> Enum.sort_by(fn x -> x.hour_local end)

      assert Enum.count(insights_data_0) == 3

      insights_0_hour_0 = Enum.at(insights_data_0, 0)
      insights_0_hour_1 = Enum.at(insights_data_0, 1)
      insights_0_hour_2 = Enum.at(insights_data_0, 2)

      assert Enum.all?(insights_data_0, fn x -> x.day_of_week == 5 end)
      assert Enum.all?(insights_data_0, fn x -> x.week_sample_first == ~D[2023-11-26] end)
      assert Enum.all?(insights_data_0, fn x -> x.week_sample_last == ~D[2023-11-26] end)
      assert Enum.all?(insights_data_0, fn x -> x.count_activities == 1 end)

      # 15/90 in the first hour
      assert insights_0_hour_0.hour_local == ~T[01:00:00]
      assert insights_0_hour_0.count_tasks == 1
      assert insights_0_hour_0.count_activities == 1
      assert insights_0_hour_0.duration_seconds == 15 * 60
      assert insights_0_hour_0.count_users == 1
      assert_in_delta(insights_0_hour_0.earnings_total_cents, 1_667, 1)
      assert insights_0_hour_0.distance_miles == Decimal.round(Decimal.from_float(2.5), 2)
      assert_in_delta(insights_0_hour_0.deduction_mileage_cents, 164, 1)
      assert_in_delta(insights_0_hour_0.earnings_avg_hr_cents, 6_668, 1)
      assert_in_delta(insights_0_hour_0.earnings_avg_hr_cents_with_mileage, 6_012, 1)

      # 60/90 in the first hour
      assert insights_0_hour_1.hour_local == ~T[02:00:00]
      assert insights_0_hour_1.count_tasks == 4
      assert insights_0_hour_1.count_activities == 1
      assert insights_0_hour_1.duration_seconds == 60 * 60
      assert insights_0_hour_1.count_users == 1
      assert_in_delta(insights_0_hour_1.earnings_total_cents, 6_667, 1)
      assert insights_0_hour_1.distance_miles == Decimal.round(Decimal.from_float(10.0), 2)
      assert_in_delta(insights_0_hour_1.deduction_mileage_cents, 655, 1)
      assert_in_delta(insights_0_hour_1.earnings_avg_hr_cents, 6_668, 1)
      assert_in_delta(insights_0_hour_1.earnings_avg_hr_cents_with_mileage, 6_012, 1)

      # 15/90 in the third hour
      assert insights_0_hour_2.hour_local == ~T[03:00:00]
      assert insights_0_hour_2.count_tasks == 1
      assert insights_0_hour_2.count_activities == 1
      assert insights_0_hour_2.duration_seconds == 15 * 60
      assert insights_0_hour_2.count_users == 1
      assert_in_delta(insights_0_hour_2.earnings_total_cents, 1_667, 1)
      assert insights_0_hour_2.distance_miles == Decimal.round(Decimal.from_float(2.5), 2)
      assert_in_delta(insights_0_hour_2.deduction_mileage_cents, 164, 1)
      assert_in_delta(insights_0_hour_2.earnings_avg_hr_cents, 6_668, 1)
      assert_in_delta(insights_0_hour_2.earnings_avg_hr_cents_with_mileage, 6_012, 1)

      # Everything for second Employer Service Class

      # data from Employer Service Class 0
      insights_data_1 =
        insights_data
        |> Enum.filter(fn x -> x.employer_service_class_id == employer_service_class_1.id end)
        |> Enum.sort_by(fn x -> x.hour_local end)

      assert Enum.count(insights_data_1) == 3
      insights_1_hour_0 = Enum.at(insights_data_1, 0)
      insights_1_hour_1 = Enum.at(insights_data_1, 1)
      insights_1_hour_2 = Enum.at(insights_data_1, 2)

      assert Enum.all?(insights_data_1, fn x -> x.day_of_week == 5 end)
      assert Enum.all?(insights_data_1, fn x -> x.week_sample_first == ~D[2023-11-26] end)
      assert Enum.all?(insights_data_1, fn x -> x.week_sample_last == ~D[2023-11-26] end)
      assert Enum.all?(insights_data_1, fn x -> x.count_activities == 1 end)

      # 15/90 in the first hour
      assert insights_1_hour_0.hour_local == ~T[01:00:00]
      assert insights_1_hour_0.count_tasks == 2
      assert insights_1_hour_0.count_activities == 1
      assert insights_1_hour_0.duration_seconds == 15 * 60
      assert insights_1_hour_0.count_users == 1
      assert_in_delta(insights_1_hour_0.earnings_total_cents, 833, 1)
      assert insights_1_hour_0.distance_miles == Decimal.round(Decimal.from_float(5.0), 2)
      assert_in_delta(insights_1_hour_0.deduction_mileage_cents, 328, 1)
      assert_in_delta(insights_1_hour_0.earnings_avg_hr_cents, 3_332, 1)
      assert_in_delta(insights_1_hour_0.earnings_avg_hr_cents_with_mileage, 2_020, 1)

      # 60/90 in the first hour
      assert insights_1_hour_1.hour_local == ~T[02:00:00]
      assert insights_1_hour_1.count_tasks == 7
      assert insights_1_hour_1.count_activities == 1
      assert insights_1_hour_1.duration_seconds == 60 * 60
      assert insights_1_hour_1.count_users == 1
      assert_in_delta(insights_1_hour_1.earnings_total_cents, 3_332, 1)
      assert insights_1_hour_1.distance_miles == Decimal.round(Decimal.from_float(20.0), 2)
      assert_in_delta(insights_1_hour_1.deduction_mileage_cents, 1_311, 1)
      assert_in_delta(insights_1_hour_1.earnings_avg_hr_cents, 3_332, 1)
      assert_in_delta(insights_1_hour_1.earnings_avg_hr_cents_with_mileage, 2_023, 1)

      # 15/90 in the third hour
      assert insights_1_hour_2.hour_local == ~T[03:00:00]
      assert insights_1_hour_2.count_tasks == 2
      assert insights_1_hour_2.count_activities == 1
      assert insights_1_hour_2.duration_seconds == 15 * 60
      assert insights_1_hour_2.count_users == 1
      assert_in_delta(insights_1_hour_2.earnings_total_cents, 833, 1)
      assert insights_1_hour_2.distance_miles == Decimal.round(Decimal.from_float(5.0), 2)
      assert_in_delta(insights_1_hour_2.deduction_mileage_cents, 328, 1)
      assert_in_delta(insights_1_hour_2.earnings_avg_hr_cents, 3_332, 1)
      assert_in_delta(insights_1_hour_2.earnings_avg_hr_cents_with_mileage, 2_020, 1)
    end

    @doc """
    In this case, the activity crosses 12/02 11:45pm - 12/03 1:15am
    Looking at insights for week 11/26 would only capture the 11:45pm-midnight on 12/02 in the stats
    Looking at insights for week 12/03 would only capture all of the hours in the stats
    """
    test "handles activities that cross day and week boundaries", state do
      user = Enum.at(state.users, 0)
      employer = Enum.at(state.employers, 0)
      service_class = Enum.at(state.service_classes, 0)

      employer_service_class =
        state.employer_service_classes
        |> Enum.find(fn x ->
          x.employer_id == employer.id and
            x.service_class_id == service_class.id
        end)

      accept_time = NaiveDateTime.new!(~D[2023-12-02], ~T[23:45:00])
      start_time = NaiveDateTime.new!(~D[2023-12-03], ~T[00:15:00])
      end_time = NaiveDateTime.new!(~D[2023-12-03], ~T[01:15:00])

      Factory.create_activity(
        user,
        employer,
        service_class,
        start_time,
        end_time,
        100.00,
        15.00,
        5,
        accept_time
      )

      # test data for 11/26 week (should only have 1 hour of stats)
      insights_data_1126 =
        CommunityInsights.calculate_avg_hr_pay_stats_for_metro_week(
          ~D[2023-11-26],
          user.metro_area_id,
          1,
          1
        )

      assert insights_data_1126 != nil

      assert Enum.count(insights_data_1126) == 1

      assert Enum.all?(insights_data_1126, fn x ->
               x.employer_service_class_id == employer_service_class.id
             end)

      insights_data_1126 = Enum.sort_by(insights_data_1126, fn x -> x.hour_local end)
      insights_1126_hour_0 = Enum.at(insights_data_1126, 0)

      # should be 11pm-midnight hour
      assert insights_1126_hour_0.hour_local == ~T[23:00:00]
      assert insights_1126_hour_0.day_of_week == 6
      assert insights_1126_hour_0.count_tasks == 1
      assert insights_1126_hour_0.count_activities == 1
      assert insights_1126_hour_0.duration_seconds == 15 * 60
      assert insights_1126_hour_0.count_users == 1
      assert insights_1126_hour_0.week_sample_first == ~D[2023-11-26]
      assert insights_1126_hour_0.week_sample_last == ~D[2023-11-26]
      assert_in_delta(insights_1126_hour_0.earnings_total_cents, 1_667, 1)
      assert insights_1126_hour_0.distance_miles == Decimal.round(Decimal.from_float(2.5), 2)
      assert_in_delta(insights_1126_hour_0.deduction_mileage_cents, 164, 1)
      assert_in_delta(insights_1126_hour_0.earnings_avg_hr_cents, 6_668, 1)
      assert insights_1126_hour_0.weighted_earnings_total_cents == 1_667 * 17

      # test data for 12/03 week (should only have 3 hour of stats)
      insights_data_1203 =
        CommunityInsights.calculate_avg_hr_pay_stats_for_metro_week(
          ~D[2023-12-03],
          user.metro_area_id,
          1,
          1
        )

      assert insights_data_1203 != nil

      assert Enum.count(insights_data_1203) == 3

      assert Enum.all?(insights_data_1203, fn x ->
               x.employer_service_class_id == employer_service_class.id
             end)

      insights_data_1203 = Enum.sort_by(insights_data_1203, fn x -> x.hour_local end)

      # should be midnight-1am hour
      insights_1203_hour_0 = Enum.at(insights_data_1203, 0)
      assert insights_1203_hour_0.day_of_week == 0
      assert insights_1203_hour_0.hour_local == ~T[00:00:00]
      assert insights_1203_hour_0.count_tasks == 4
      assert insights_1203_hour_0.count_activities == 1
      assert insights_1203_hour_0.duration_seconds == 60 * 60
      assert insights_1203_hour_0.count_users == 1
      assert insights_1203_hour_0.week_sample_first == ~D[2023-12-03]
      assert insights_1203_hour_0.week_sample_last == ~D[2023-12-03]
      assert_in_delta(insights_1203_hour_0.earnings_total_cents, 6_667, 1)
      assert insights_1203_hour_0.distance_miles == Decimal.round(Decimal.from_float(10.0), 2)
      assert_in_delta(insights_1203_hour_0.deduction_mileage_cents, 655, 1)
      assert_in_delta(insights_1203_hour_0.earnings_avg_hr_cents, 6_668, 1)
      assert insights_1203_hour_0.weighted_earnings_total_cents == 6_667 * 17

      # should be 1am-2am hour
      insights_1203_hour_1 = Enum.at(insights_data_1203, 1)
      assert insights_1203_hour_1.day_of_week == 0
      assert insights_1203_hour_1.hour_local == ~T[01:00:00]
      assert insights_1203_hour_1.count_tasks == 1
      assert insights_1203_hour_1.count_activities == 1
      assert insights_1203_hour_1.duration_seconds == 15 * 60
      assert insights_1203_hour_1.count_users == 1
      assert insights_1203_hour_1.week_sample_first == ~D[2023-12-03]
      assert insights_1203_hour_1.week_sample_last == ~D[2023-12-03]
      assert_in_delta(insights_1203_hour_1.earnings_total_cents, 1_667, 1)
      assert insights_1203_hour_1.distance_miles == Decimal.round(Decimal.from_float(2.5), 2)
      assert_in_delta(insights_1203_hour_1.deduction_mileage_cents, 164, 1)
      assert_in_delta(insights_1203_hour_1.earnings_avg_hr_cents, 6_668, 1)
      assert insights_1203_hour_1.weighted_earnings_total_cents == 1_667 * 17

      # should be 11pm-midnight hour
      insights_1203_hour_2 = Enum.at(insights_data_1203, 2)
      assert insights_1203_hour_2.day_of_week == 6
      assert insights_1203_hour_2.hour_local == ~T[23:00:00]
      assert insights_1203_hour_2.count_tasks == 1
      assert insights_1203_hour_2.count_activities == 1
      assert insights_1203_hour_2.duration_seconds == 15 * 60
      assert insights_1203_hour_2.count_users == 1
      assert insights_1203_hour_2.week_sample_first == ~D[2023-11-26]
      assert insights_1203_hour_2.week_sample_last == ~D[2023-11-26]
      assert_in_delta(insights_1203_hour_2.earnings_total_cents, 1_667, 1)
      assert insights_1203_hour_2.distance_miles == Decimal.round(Decimal.from_float(2.5), 2)
      assert_in_delta(insights_1203_hour_2.deduction_mileage_cents, 164, 1)
      assert_in_delta(insights_1203_hour_2.earnings_avg_hr_cents, 6_668, 1)
      assert insights_1203_hour_2.weighted_earnings_total_cents == 1_667 * 16
    end

    test "handles when there is no mileage info", state do
      user = Enum.at(state.users, 0)
      employer = Enum.at(state.employers, 0)
      service_class = Enum.at(state.service_classes, 0)

      employer_service_class =
        state.employer_service_classes
        |> Enum.find(fn x ->
          x.employer_id == employer.id and
            x.service_class_id == service_class.id
        end)

      accept_time = NaiveDateTime.new!(~D[2023-12-01], ~T[01:45:00])
      start_time = NaiveDateTime.new!(~D[2023-12-01], ~T[02:15:00])
      end_time = NaiveDateTime.new!(~D[2023-12-01], ~T[03:15:00])

      Factory.create_activity(
        user,
        employer,
        service_class,
        start_time,
        end_time,
        100.00,
        nil,
        5,
        accept_time
      )

      insights_data =
        CommunityInsights.calculate_avg_hr_pay_stats_for_metro_week(
          ~D[2023-11-26],
          user.metro_area_id,
          1,
          1
        )

      assert insights_data != nil

      insights_data = Enum.sort_by(insights_data, fn x -> x.hour_local end)

      assert Enum.count(insights_data) == 3

      assert Enum.all?(insights_data, fn x ->
               x.employer_service_class_id == employer_service_class.id
             end)

      assert Enum.all?(insights_data, fn x -> x.deduction_mileage_cents == 0 end)

      assert Enum.all?(insights_data, fn x ->
               x.earnings_avg_hr_cents == x.earnings_avg_hr_cents_with_mileage
             end)
    end
  end

  describe "Update Community Insights Pay Stats" do
    test "Saves stats", state do
      user_0 = Enum.at(state.users, 0)
      user_1 = Enum.at(state.users, 1)
      employer = Enum.at(state.employers, 2)
      service_class = Enum.at(state.service_classes, 0)

      employer_service_class =
        state.employer_service_classes
        |> Enum.find(fn x ->
          x.employer_id == employer.id and
            x.service_class_id == service_class.id
        end)

      activity_0_accept_time = NaiveDateTime.new!(~D[2023-12-01], ~T[21:45:00])
      activity_0_start_time = NaiveDateTime.new!(~D[2023-12-01], ~T[22:15:00])
      activity_0_end_time = NaiveDateTime.new!(~D[2023-12-01], ~T[23:15:00])

      Factory.create_activity(
        user_0,
        employer,
        service_class,
        activity_0_start_time,
        activity_0_end_time,
        100.00,
        15.00,
        5,
        activity_0_accept_time
      )

      activity_1_accept_time = NaiveDateTime.new!(~D[2023-12-02], ~T[20:45:00])
      activity_1_start_time = NaiveDateTime.new!(~D[2023-12-02], ~T[21:15:00])
      activity_1_end_time = NaiveDateTime.new!(~D[2023-12-02], ~T[22:15:00])

      Factory.create_activity(
        user_1,
        employer,
        service_class,
        activity_1_start_time,
        activity_1_end_time,
        100.00,
        15.00,
        5,
        activity_1_accept_time
      )

      :ok =
        CommunityInsights.update_avg_hr_pay_stats_for_metro_week(
          ~D[2023-11-26],
          user_0.metro_area_id,
          1,
          1
        )

      stats =
        CommunityInsights.query()
        |> Repo.all()

      assert stats != nil
      assert Enum.count(stats) == 6

      assert Enum.all?(stats, fn stat ->
               stat.employer_service_class_id == employer_service_class.id
             end)

      assert Enum.all?(stats, fn stat -> stat.metro_area_id == user_0.metro_area_id end)
      assert Enum.all?(stats, fn stat -> stat.week_start_date == ~D[2023-11-26] end)
      assert Enum.count(stats, fn stat -> stat.hour_local == ~T[20:00:00] end) == 1
      assert Enum.count(stats, fn stat -> stat.hour_local == ~T[21:00:00] end) == 2
      assert Enum.count(stats, fn stat -> stat.hour_local == ~T[22:00:00] end) == 2
      assert Enum.count(stats, fn stat -> stat.hour_local == ~T[23:00:00] end) == 1
      assert Enum.count(stats, fn stat -> stat.day_of_week == 5 end) == 3
      assert Enum.count(stats, fn stat -> stat.day_of_week == 6 end) == 3
    end

    test "Removes stats when they no longer are represented in the data", state do
      user_0 = Enum.at(state.users, 0)
      user_1 = Enum.at(state.users, 1)
      employer = Enum.at(state.employers, 2)
      service_class = Enum.at(state.service_classes, 0)

      employer_service_class =
        state.employer_service_classes
        |> Enum.find(fn x ->
          x.employer_id == employer.id and
            x.service_class_id == service_class.id
        end)

      activity_0_accept_time = NaiveDateTime.new!(~D[2023-12-01], ~T[21:45:00])
      activity_0_start_time = NaiveDateTime.new!(~D[2023-12-01], ~T[22:15:00])
      activity_0_end_time = NaiveDateTime.new!(~D[2023-12-01], ~T[23:15:00])

      Factory.create_activity(
        user_0,
        employer,
        service_class,
        activity_0_start_time,
        activity_0_end_time,
        100.00,
        15.00,
        5,
        activity_0_accept_time
      )

      activity_1_accept_time = NaiveDateTime.new!(~D[2023-12-02], ~T[20:45:00])
      activity_1_start_time = NaiveDateTime.new!(~D[2023-12-02], ~T[21:15:00])
      activity_1_end_time = NaiveDateTime.new!(~D[2023-12-02], ~T[22:15:00])

      activity_to_delete =
        Factory.create_activity(
          user_1,
          employer,
          service_class,
          activity_1_start_time,
          activity_1_end_time,
          100.00,
          15.00,
          5,
          activity_1_accept_time
        )

      :ok =
        CommunityInsights.update_avg_hr_pay_stats_for_metro_week(
          ~D[2023-11-26],
          user_0.metro_area_id,
          1,
          1
        )

      stats =
        CommunityInsights.query()
        |> Repo.all()

      assert stats != nil
      assert Enum.count(stats) == 6

      assert Enum.all?(stats, fn stat ->
               stat.employer_service_class_id == employer_service_class.id
             end)

      assert Enum.all?(stats, fn stat -> stat.metro_area_id == user_0.metro_area_id end)
      assert Enum.all?(stats, fn stat -> stat.week_start_date == ~D[2023-11-26] end)
      assert Enum.count(stats, fn stat -> stat.hour_local == ~T[20:00:00] end) == 1
      assert Enum.count(stats, fn stat -> stat.hour_local == ~T[21:00:00] end) == 2
      assert Enum.count(stats, fn stat -> stat.hour_local == ~T[22:00:00] end) == 2
      assert Enum.count(stats, fn stat -> stat.hour_local == ~T[23:00:00] end) == 1
      assert Enum.count(stats, fn stat -> stat.day_of_week == 5 end) == 3
      assert Enum.count(stats, fn stat -> stat.day_of_week == 6 end) == 3

      Driving.delete_activities(activity_to_delete.activity_id)

      :ok =
        CommunityInsights.update_avg_hr_pay_stats_for_metro_week(
          ~D[2023-11-26],
          user_0.metro_area_id,
          1,
          1
        )

      stats =
        CommunityInsights.query()
        |> Repo.all()

      assert stats != nil
      assert Enum.count(stats) == 3

      assert Enum.all?(stats, fn stat ->
               stat.employer_service_class_id == employer_service_class.id
             end)

      assert Enum.all?(stats, fn stat -> stat.metro_area_id == user_0.metro_area_id end)
      assert Enum.all?(stats, fn stat -> stat.week_start_date == ~D[2023-11-26] end)
      assert Enum.count(stats, fn stat -> stat.hour_local == ~T[21:00:00] end) == 1
      assert Enum.count(stats, fn stat -> stat.hour_local == ~T[22:00:00] end) == 1
      assert Enum.count(stats, fn stat -> stat.hour_local == ~T[23:00:00] end) == 1
      assert Enum.count(stats, fn stat -> stat.day_of_week == 5 end) == 3
    end

    test "Updates existing stats in place", state do
      user_0 = Enum.at(state.users, 0)
      user_1 = Enum.at(state.users, 1)
      employer = Enum.at(state.employers, 2)
      service_class = Enum.at(state.service_classes, 0)

      employer_service_class =
        state.employer_service_classes
        |> Enum.find(fn x ->
          x.employer_id == employer.id and
            x.service_class_id == service_class.id
        end)

      activity_0_accept_time = NaiveDateTime.new!(~D[2023-12-01], ~T[21:15:00])
      activity_0_start_time = NaiveDateTime.new!(~D[2023-12-01], ~T[21:30:00])
      activity_0_end_time = NaiveDateTime.new!(~D[2023-12-01], ~T[21:45:00])

      Factory.create_activity(
        user_0,
        employer,
        service_class,
        activity_0_start_time,
        activity_0_end_time,
        100.00,
        15.00,
        5,
        activity_0_accept_time
      )

      :ok =
        CommunityInsights.update_avg_hr_pay_stats_for_metro_week(
          ~D[2023-11-26],
          user_0.metro_area_id,
          1,
          1
        )

      stats_0 =
        CommunityInsights.query()
        |> Repo.all()

      assert stats_0 != nil
      assert Enum.count(stats_0) == 1
      stat_0 = Enum.at(stats_0, 0)
      assert stat_0.employer_service_class_id == employer_service_class.id
      assert stat_0.metro_area_id == user_0.metro_area_id
      assert stat_0.week_start_date == ~D[2023-11-26]
      assert stat_0.hour_local == ~T[21:00:00]
      assert stat_0.day_of_week == 5
      assert stat_0.count_users == 1
      assert stat_0.count_activities == 1

      activity_1_accept_time = NaiveDateTime.new!(~D[2023-12-01], ~T[21:00:00])
      activity_1_start_time = NaiveDateTime.new!(~D[2023-12-01], ~T[21:15:00])
      activity_1_end_time = NaiveDateTime.new!(~D[2023-12-01], ~T[21:30:00])

      Factory.create_activity(
        user_1,
        employer,
        service_class,
        activity_1_start_time,
        activity_1_end_time,
        100.00,
        15.00,
        5,
        activity_1_accept_time
      )

      :ok =
        CommunityInsights.update_avg_hr_pay_stats_for_metro_week(
          ~D[2023-11-26],
          user_0.metro_area_id,
          1,
          1
        )

      stats_1 =
        CommunityInsights.query()
        |> Repo.all()

      assert stats_1 != nil
      assert Enum.count(stats_1) == 1
      stat_1 = Enum.at(stats_1, 0)
      assert stat_1.id == stat_0.id
      assert stat_1.employer_service_class_id == employer_service_class.id
      assert stat_1.metro_area_id == user_0.metro_area_id
      assert stat_1.week_start_date == ~D[2023-11-26]
      assert stat_1.hour_local == ~T[21:00:00]
      assert stat_1.day_of_week == 5
      assert stat_1.count_users == 2
      assert stat_1.count_activities == 2
    end
  end
end
