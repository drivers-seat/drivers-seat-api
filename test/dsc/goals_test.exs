defmodule DriversSeatCoop.GoalsTest do
  use DriversSeatCoop.DataCase, async: true

  alias DriversSeatCoop.Accounts.User
  alias DriversSeatCoop.Earnings
  alias DriversSeatCoop.Factory
  alias DriversSeatCoop.Goals
  alias DriversSeatCoop.Util.DateTimeUtil

  describe "get_goals" do
    test "filters for user" do
      user_1 = Factory.create_user()
      user_2 = Factory.create_user()

      user_1_goal = %{
        type: :earnings,
        frequency: :day,
        sub_frequency: "1",
        amount: 3295,
        start_date: ~D[2023-05-24]
      }

      user_1_sub_goal = %{
        "1" => 3295
      }

      user_2_goal = %{
        type: :earnings,
        frequency: :day,
        sub_frequency: "3",
        amount: 1492,
        start_date: ~D[2023-05-26]
      }

      user_2_sub_goal = %{
        "3" => 1492
      }

      expected_user_1 = for_compare([user_1_goal])
      expected_user_2 = for_compare([user_2_goal])

      {:ok, _} =
        Goals.update_goals(user_1.id, :earnings, :day, ~D[2023-05-24], user_1_sub_goal, nil)

      {:ok, _} =
        Goals.update_goals(user_2.id, :earnings, :day, ~D[2023-05-26], user_2_sub_goal, nil)

      actual_user_1 =
        Goals.get_goals(user_1.id, :day)
        |> for_compare()

      actual_user_2 =
        Goals.get_goals(user_2.id, :day)
        |> for_compare()

      assert expected_user_1 == actual_user_1
      assert expected_user_2 == actual_user_2
    end

    test "filters for frequency" do
      user = Factory.create_user()

      goal_day = %{
        type: :earnings,
        frequency: :day,
        sub_frequency: "1",
        amount: 3295,
        start_date: ~D[2023-05-24]
      }

      sub_goal_day = %{
        "1" => 3295
      }

      goal_week = %{
        type: :earnings,
        frequency: :week,
        sub_frequency: "all",
        amount: 32_950,
        start_date: ~D[2023-05-22]
      }

      sub_goal_week = %{
        "all" => 32_950
      }

      expected_day = for_compare([goal_day])
      expected_week = for_compare([goal_week])

      {:ok, _} = Goals.update_goals(user.id, :earnings, :day, ~D[2023-05-24], sub_goal_day, nil)

      {:ok, _} = Goals.update_goals(user.id, :earnings, :week, ~D[2023-05-22], sub_goal_week, nil)

      actual_day =
        Goals.get_goals(user.id, :day)
        |> for_compare()

      actual_week =
        Goals.get_goals(user.id, :week)
        |> for_compare()

      assert expected_day == actual_day
      assert expected_week == actual_week
    end
  end

  describe "delete_goals" do
    test "filters for user" do
      user_1 = Factory.create_user()
      user_2 = Factory.create_user()

      user_1_sub_goal = %{
        "1" => 3295
      }

      user_2_sub_goal = %{
        "3" => 1492
      }

      {:ok, _} =
        Goals.update_goals(user_1.id, :earnings, :day, ~D[2023-05-24], user_1_sub_goal, nil)

      {:ok, _} =
        Goals.update_goals(user_2.id, :earnings, :day, ~D[2023-05-26], user_2_sub_goal, nil)

      actual_user_1 =
        Goals.get_goals(user_1.id, :day)
        |> for_compare()

      actual_user_2 =
        Goals.get_goals(user_2.id, :day)
        |> for_compare()

      assert Enum.count(actual_user_1) == 1
      assert Enum.count(actual_user_2) == 1

      {:ok, _} = Goals.delete_goals(user_1.id, :earnings, :day, ~D[2023-05-24])

      actual_user_1 =
        Goals.get_goals(user_1.id, :day)
        |> for_compare()

      actual_user_2 =
        Goals.get_goals(user_2.id, :day)
        |> for_compare()

      assert not Enum.any?(actual_user_1)
      assert Enum.count(actual_user_2) == 1
    end

    test "filters for frequency" do
      user = Factory.create_user()

      sub_goal_day = %{
        "1" => 3295
      }

      goal_week = %{
        type: :earnings,
        frequency: :week,
        sub_frequency: "all",
        amount: 32_950,
        start_date: ~D[2023-05-22]
      }

      sub_goal_week = %{
        "all" => 32_950
      }

      expected_week = for_compare([goal_week])

      {:ok, _} = Goals.update_goals(user.id, :earnings, :day, ~D[2023-05-24], sub_goal_day, nil)

      {:ok, _} = Goals.update_goals(user.id, :earnings, :week, ~D[2023-05-22], sub_goal_week, nil)

      actual_day =
        Goals.get_goals(user.id, :day)
        |> for_compare()

      actual_week =
        Goals.get_goals(user.id, :week)
        |> for_compare()

      assert Enum.count(actual_day) == 1
      assert Enum.count(actual_week) == 1

      {:ok, _} = Goals.delete_goals(user.id, :earnings, :day, ~D[2023-05-24])

      actual_day =
        Goals.get_goals(user.id, :day)
        |> for_compare()

      actual_week =
        Goals.get_goals(user.id, :week)
        |> for_compare()

      assert [] == actual_day
      assert expected_week == actual_week
    end

    test "filters for start_date" do
      user = Factory.create_user()

      goal_1 = %{
        type: :earnings,
        frequency: :day,
        sub_frequency: "1",
        amount: 3295,
        start_date: ~D[2023-05-24]
      }

      sub_goal_1 = %{
        "1" => 3295
      }

      goal_2 = %{
        type: :earnings,
        frequency: :day,
        sub_frequency: "all",
        amount: 32_950,
        start_date: ~D[2023-05-22]
      }

      sub_goal_2 = %{
        "all" => 32_950
      }

      expected = for_compare([goal_1, goal_2])

      {:ok, _} = Goals.update_goals(user.id, :earnings, :day, ~D[2023-05-24], sub_goal_1, nil)

      {:ok, _} = Goals.update_goals(user.id, :earnings, :day, ~D[2023-05-22], sub_goal_2, nil)

      actual =
        Goals.get_goals(user.id, :day)
        |> for_compare()

      assert expected == actual

      expected = for_compare(goal_2)

      {:ok, _} = Goals.delete_goals(user.id, :earnings, :day, ~D[2023-05-24])

      actual =
        Goals.get_goals(user.id, :day)
        |> for_compare()

      assert expected == actual
    end
  end

  describe "update_goals" do
    test "breaks out each subgoal into individual goal records" do
      user = Factory.create_user()

      sub_goals = %{
        "1" => 3295,
        "2" => 4895
      }

      goal_1 = %{
        type: :earnings,
        frequency: :day,
        sub_frequency: "1",
        amount: 3295,
        start_date: ~D[2023-05-24]
      }

      goal_2 = %{
        type: :earnings,
        frequency: :day,
        sub_frequency: "2",
        amount: 4895,
        start_date: ~D[2023-05-24]
      }

      expected =
        for_compare([
          goal_1,
          goal_2
        ])

      {:ok, _} = Goals.update_goals(user.id, :earnings, :day, ~D[2023-05-24], sub_goals, nil)

      actual =
        Goals.get_goals(user.id, :day)
        |> for_compare()

      assert expected == actual
    end

    test "removes subgoals that are no longer specified" do
      user = Factory.create_user()

      goal_1 = %{
        type: :earnings,
        frequency: :day,
        sub_frequency: "1",
        amount: 3295,
        start_date: ~D[2023-05-24]
      }

      goal_2 = %{
        type: :earnings,
        frequency: :day,
        sub_frequency: "2",
        amount: 4895,
        start_date: ~D[2023-05-24]
      }

      goal_3 = %{
        type: :earnings,
        frequency: :day,
        sub_frequency: "3",
        amount: 5892,
        start_date: ~D[2023-05-24]
      }

      sub_goals_1 = %{
        "1" => 3295,
        "2" => 4895
      }

      expected_1 = for_compare([goal_1, goal_2])

      {:ok, _} = Goals.update_goals(user.id, :earnings, :day, ~D[2023-05-24], sub_goals_1, nil)

      actual_1 =
        Goals.get_goals(user.id, :day)
        |> for_compare()

      assert expected_1 == actual_1

      sub_goals_2 = %{
        "1" => 3295,
        "3" => 5892
      }

      expected_2 = for_compare([goal_1, goal_3])

      {:ok, _} = Goals.update_goals(user.id, :earnings, :day, ~D[2023-05-24], sub_goals_2, nil)

      actual_2 =
        Goals.get_goals(user.id, :day)
        |> for_compare()

      assert expected_2 == actual_2
    end

    test "handles replace_date properly" do
      user = Factory.create_user()

      goal_1 = %{
        type: :earnings,
        frequency: :day,
        sub_frequency: "1",
        amount: 3295,
        start_date: ~D[2023-05-24]
      }

      goal_2 = %{
        type: :earnings,
        frequency: :day,
        sub_frequency: "2",
        amount: 4895,
        start_date: ~D[2023-05-24]
      }

      goal_3 = %{
        type: :earnings,
        frequency: :day,
        sub_frequency: "3",
        amount: 5892,
        start_date: ~D[2023-05-24]
      }

      # basic creation
      sub_goals_1 = %{
        "1" => 3295,
        "2" => 4895
      }

      expected_1 = for_compare([goal_1, goal_2])

      {:ok, _} = Goals.update_goals(user.id, :earnings, :day, ~D[2023-05-24], sub_goals_1, nil)

      actual_1 =
        Goals.get_goals(user.id, :day)
        |> for_compare()

      assert expected_1 == actual_1

      # add new goals should keep existing goals in place and add new ones
      sub_goals_2 = %{
        "1" => 3295,
        "3" => 5892
      }

      expected_2 =
        for_compare(
          [goal_1, goal_2] ++
            Enum.map([goal_1, goal_3], fn g -> Map.put(g, :start_date, ~D[2023-06-21]) end)
        )

      {:ok, _} = Goals.update_goals(user.id, :earnings, :day, ~D[2023-06-21], sub_goals_2, nil)

      actual_2 =
        Goals.get_goals(user.id, :day)
        |> for_compare()

      assert expected_2 == actual_2

      # add new goals with replace date should just replace the ones, but keep original
      sub_goals_3 = %{
        "1" => 3295,
        "2" => 4895
      }

      expected_3 =
        for_compare(
          [goal_1, goal_2] ++
            Enum.map([goal_1, goal_2], fn g -> Map.put(g, :start_date, ~D[2023-07-04]) end)
        )

      {:ok, _} =
        Goals.update_goals(user.id, :earnings, :day, ~D[2023-07-04], sub_goals_3, ~D[2023-06-21])

      actual_3 =
        Goals.get_goals(user.id, :day)
        |> for_compare()

      assert expected_3 == actual_3
    end

    test "normalizes goal start_date to beginning of period" do
      user = Factory.create_user()

      goal_1 = %{
        type: :earnings,
        frequency: :week,
        sub_frequency: "1",
        amount: 3295,
        start_date: ~D[2023-05-22]
      }

      sub_goals_1 = %{
        "1" => 3295
      }

      expected_1 = for_compare([goal_1])

      {:ok, _} = Goals.update_goals(user.id, :earnings, :week, ~D[2023-05-24], sub_goals_1, nil)

      actual_1 =
        Goals.get_goals(user.id, :week)
        |> for_compare()

      assert expected_1 == actual_1
    end
  end

  describe "calculate_goal_performance" do
    test "does not calculate performance in the future - day" do
      user =
        Factory.create_user(%{
          timezone: "America/Los_Angeles"
        })

      today = User.datetime_to_working_day(DateTime.utc_now(), user)
      tomorrow = Date.add(today, 1)

      _goal = Factory.create_default_goal(user.id, :earnings, :day, ~D[2023-01-01], 1_000)

      {:not_calculated, :did_not_work, _} =
        Goals.calculate_goal_performance(user.id, :earnings, :day, today)

      {:not_calculated, :window_in_future, _} =
        Goals.calculate_goal_performance(user.id, :earnings, :day, tomorrow)
    end

    test "does not calculate performance in the future - week" do
      user =
        Factory.create_user(%{
          timezone: "America/Los_Angeles"
        })

      today = User.datetime_to_working_day(DateTime.utc_now(), user)
      {this_week, _} = DateTimeUtil.get_time_window_for_date(today, :week)
      next_week = Date.add(this_week, 7)

      _goal = Factory.create_default_goal(user.id, :earnings, :day, ~D[2023-01-01], 1_000)

      {:not_calculated, :did_not_work, _} =
        Goals.calculate_goal_performance(user.id, :earnings, :day, this_week)

      {:not_calculated, :window_in_future, _} =
        Goals.calculate_goal_performance(user.id, :earnings, :day, next_week)
    end

    test "does not calculate performance in the future - month" do
      user =
        Factory.create_user(%{
          timezone: "America/Los_Angeles"
        })

      today = User.datetime_to_working_day(DateTime.utc_now(), user)
      {this_month, end_of_month} = DateTimeUtil.get_time_window_for_date(today, :month)
      next_month = Date.add(end_of_month, 1)

      _goal = Factory.create_default_goal(user.id, :earnings, :day, ~D[2023-01-01], 1_000)

      {:not_calculated, :did_not_work, _} =
        Goals.calculate_goal_performance(user.id, :earnings, :day, this_month)

      {:not_calculated, :window_in_future, _} =
        Goals.calculate_goal_performance(user.id, :earnings, :day, next_month)
    end
  end

  describe "calculate_goal_performance - day" do
    test "uses 'all' goal for each day" do
      user =
        Factory.create_user(%{
          timezone: "America/Los_Angeles"
        })

      _goal = Factory.create_default_goal(user.id, :earnings, :day, ~D[2023-05-01], 1_000)

      _activity_d1_1 = Factory.create_work_activity(user, ~D[2023-05-01], 532)
      _activity_d1_2 = Factory.create_incentive_activity(user, ~D[2023-05-01], 268)

      _activity_d2_1 = Factory.create_work_activity(user, ~D[2023-05-02], 200)
      _activity_d2_2 = Factory.create_incentive_activity(user, ~D[2023-05-02], 900)

      Earnings.update_timespans_and_allocations_for_user_workday(user, ~D[2023-05-01])
      Earnings.update_timespans_and_allocations_for_user_workday(user, ~D[2023-05-02])

      {:ok, performance, _goal} =
        Goals.calculate_goal_performance(user.id, :earnings, :day, ~D[2023-05-01])

      assert performance.performance_amount == 800
      assert Decimal.to_float(performance.performance_percent) == 0.8

      {:ok, performance, _goal} =
        Goals.calculate_goal_performance(user.id, :earnings, :day, ~D[2023-05-02])

      assert performance.performance_amount == 1_100
      assert Decimal.to_float(performance.performance_percent) == 1.1
    end

    test "uses specific day goals" do
      user =
        Factory.create_user(%{
          timezone: "America/Los_Angeles"
        })

      # 0: Sunday, 1: Monday
      Goals.update_goals(
        user.id,
        :earnings,
        :day,
        ~D[2023-05-01],
        %{"0" => 1_000, "1" => 2_200},
        nil
      )

      _activity_sun_1 = Factory.create_work_activity(user, ~D[2023-05-07], 532)
      _activity_sun_2 = Factory.create_incentive_activity(user, ~D[2023-05-07], 268)

      _activity_mon_1 = Factory.create_work_activity(user, ~D[2023-05-08], 200)
      _activity_mon_2 = Factory.create_incentive_activity(user, ~D[2023-05-08], 900)

      _activity_tue_1 = Factory.create_work_activity(user, ~D[2023-05-09], 200)
      _activity_tue_2 = Factory.create_incentive_activity(user, ~D[2023-05-09], 900)

      Earnings.update_timespans_and_allocations_for_user_workday(user, ~D[2023-05-07])
      Earnings.update_timespans_and_allocations_for_user_workday(user, ~D[2023-05-08])
      Earnings.update_timespans_and_allocations_for_user_workday(user, ~D[2023-05-09])

      # calculate using sunday goal
      {:ok, performance, _goal} =
        Goals.calculate_goal_performance(user.id, :earnings, :day, ~D[2023-05-07])

      assert performance.performance_amount == 800
      assert Decimal.to_float(performance.performance_percent) == 0.8

      # calculate using monday goal
      {:ok, performance, _goal} =
        Goals.calculate_goal_performance(user.id, :earnings, :day, ~D[2023-05-08])

      assert performance.performance_amount == 1_100
      assert Decimal.to_float(performance.performance_percent) == 0.5

      {:not_calculated, :no_goal_available} =
        Goals.calculate_goal_performance(user.id, :earnings, :day, ~D[2023-05-09])
    end

    test "picks the most appropriate goal considering start_date and frequency first" do
      user =
        Factory.create_user(%{
          timezone: "America/Los_Angeles"
        })

      # 0: Sunday, 2: Tuesday
      Goals.update_goals(
        user.id,
        :earnings,
        :day,
        ~D[2023-04-01],
        %{"0" => 1_000, "2" => 800},
        nil
      )

      # 0: Sunday, 1: Monday
      Goals.update_goals(
        user.id,
        :earnings,
        :day,
        ~D[2023-05-07],
        %{"0" => 2_000, "1" => 1_200},
        nil
      )

      _activity_sun_1 = Factory.create_work_activity(user, ~D[2023-04-30], 800)
      _activity_mon_1 = Factory.create_work_activity(user, ~D[2023-05-01], 1_100)
      _activity_tue_1 = Factory.create_work_activity(user, ~D[2023-05-02], 600)

      Earnings.update_timespans_and_allocations_for_user_workday(user, ~D[2023-04-30])
      Earnings.update_timespans_and_allocations_for_user_workday(user, ~D[2023-05-01])
      Earnings.update_timespans_and_allocations_for_user_workday(user, ~D[2023-05-02])

      # calculate using sunday goal
      {:ok, performance, _goal} =
        Goals.calculate_goal_performance(user.id, :earnings, :day, ~D[2023-04-30])

      assert performance.performance_amount == 800
      assert Decimal.to_float(performance.performance_percent) == 0.8

      # calculate for monday, but no goal
      {:not_calculated, :no_goal_available} =
        Goals.calculate_goal_performance(user.id, :earnings, :day, ~D[2023-05-01])

      # calculate using tuesday goal
      {:ok, performance, _goal} =
        Goals.calculate_goal_performance(user.id, :earnings, :day, ~D[2023-05-02])

      assert performance.performance_amount == 600
      assert Decimal.to_float(performance.performance_percent) == 0.75

      _activity_sun_2 = Factory.create_work_activity(user, ~D[2023-05-07], 3_000)
      _activity_mon_2 = Factory.create_work_activity(user, ~D[2023-05-08], 2_400)
      _activity_tue_2 = Factory.create_work_activity(user, ~D[2023-05-09], 850)

      Earnings.update_timespans_and_allocations_for_user_workday(user, ~D[2023-05-07])
      Earnings.update_timespans_and_allocations_for_user_workday(user, ~D[2023-05-08])
      Earnings.update_timespans_and_allocations_for_user_workday(user, ~D[2023-05-09])

      # calculate using sunday goal
      {:ok, performance, _goal} =
        Goals.calculate_goal_performance(user.id, :earnings, :day, ~D[2023-05-07])

      assert performance.performance_amount == 3_000
      assert Decimal.to_float(performance.performance_percent) == 1.5

      # calculate using monday goal
      {:ok, performance, _goal} =
        Goals.calculate_goal_performance(user.id, :earnings, :day, ~D[2023-05-08])

      assert performance.performance_amount == 2_400
      assert Decimal.to_float(performance.performance_percent) == 2.0

      # calculate for tuesday, but no goal
      {:not_calculated, :no_goal_available} =
        Goals.calculate_goal_performance(user.id, :earnings, :day, ~D[2023-05-09])
    end

    test "returns empty when no goal available - goal-start-date" do
      user =
        Factory.create_user(%{
          timezone: "America/Los_Angeles"
        })

      _goal = Factory.create_default_goal(user.id, :earnings, :day, ~D[2023-05-02], 1_000)

      _activity_d1_1 = Factory.create_work_activity(user, ~D[2023-05-01], 532)
      _activity_d1_2 = Factory.create_incentive_activity(user, ~D[2023-05-01], 268)

      _activity_d2_1 = Factory.create_work_activity(user, ~D[2023-05-02], 200)
      _activity_d2_2 = Factory.create_incentive_activity(user, ~D[2023-05-02], 900)

      Earnings.update_timespans_and_allocations_for_user_workday(user, ~D[2023-05-01])
      Earnings.update_timespans_and_allocations_for_user_workday(user, ~D[2023-05-02])

      {:not_calculated, :no_goal_available} =
        Goals.calculate_goal_performance(user.id, :earnings, :day, ~D[2023-05-01])

      {:ok, performance, _goal} =
        Goals.calculate_goal_performance(user.id, :earnings, :day, ~D[2023-05-02])

      assert performance.performance_amount == 1_100
      assert Decimal.to_float(performance.performance_percent) == 1.1
    end

    test "returns empty when no activitiy or work-time available" do
      user =
        Factory.create_user(%{
          timezone: "America/Los_Angeles"
        })

      _goal = Factory.create_default_goal(user.id, :earnings, :day, ~D[2023-05-01], 1_000)

      {:not_calculated, :did_not_work, _goal} =
        Goals.calculate_goal_performance(user.id, :earnings, :day, ~D[2023-05-01])
    end

    test "no earnings activity but has work-time should produce performance measurement" do
      user =
        Factory.create_user(%{
          timezone: "America/Los_Angeles"
        })

      _goal = Factory.create_default_goal(user.id, :earnings, :day, ~D[2023-05-01], 1_000)

      _shift =
        Factory.create_shift(%{
          user_id: user.id,
          start_time: get_utc_date(~N[2023-05-01T09:15:00Z], user.timezone),
          end_time: get_utc_date(~N[2023-05-01T17:15:00Z], user.timezone)
        })

      Earnings.update_timespans_and_allocations_for_user_workday(
        user,
        ~D[2023-05-01],
        "user_facing"
      )

      Earnings.update_timespans_and_allocations_for_user_workday(
        user,
        ~D[2023-05-02],
        "user_facing"
      )

      {:ok, performance, _goal} =
        Goals.calculate_goal_performance(user.id, :earnings, :day, ~D[2023-05-01])

      assert performance.performance_amount == 0
      assert Decimal.to_float(performance.performance_percent) == 0

      {:not_calculated, :did_not_work, _goal} =
        Goals.calculate_goal_performance(user.id, :earnings, :day, ~D[2023-05-02])
    end
  end

  describe "calculate_goal_performance - week and month" do
    test "Calculates weekly performance correctly" do
      user =
        Factory.create_user(%{
          timezone: "America/Los_Angeles"
        })

      _goal = Factory.create_default_goal(user.id, :earnings, :week, ~D[2023-05-01], 1_000)

      _activity_w0 = Factory.create_work_activity(user, ~D[2023-04-30], 300)
      _activity_w1_1 = Factory.create_work_activity(user, ~D[2023-05-01], 800)
      _activity_w1_2 = Factory.create_work_activity(user, ~D[2023-05-02], 200)
      _activity_w2 = Factory.create_work_activity(user, ~D[2023-05-08], 200)

      Earnings.update_timespans_and_allocations_for_user_workday(user, ~D[2023-04-30])
      Earnings.update_timespans_and_allocations_for_user_workday(user, ~D[2023-05-01])
      Earnings.update_timespans_and_allocations_for_user_workday(user, ~D[2023-05-02])
      Earnings.update_timespans_and_allocations_for_user_workday(user, ~D[2023-05-08])

      {:not_calculated, :no_goal_available} =
        Goals.calculate_goal_performance(user.id, :earnings, :week, ~D[2023-04-24])

      {:ok, performance, _goal} =
        Goals.calculate_goal_performance(user.id, :earnings, :week, ~D[2023-05-01])

      assert performance.performance_amount == 1_000
      assert Decimal.to_float(performance.performance_percent) == 1

      {:ok, performance, _goal} =
        Goals.calculate_goal_performance(user.id, :earnings, :week, ~D[2023-05-08])

      assert performance.performance_amount == 200
      assert Decimal.to_float(performance.performance_percent) == 0.2

      _goal = Factory.create_default_goal(user.id, :earnings, :week, ~D[2023-04-01], 500)

      {:ok, performance, _goal} =
        Goals.calculate_goal_performance(user.id, :earnings, :week, ~D[2023-04-24])

      assert performance.performance_amount == 300
      assert Decimal.to_float(performance.performance_percent) == 0.6

      {:ok, performance, _goal} =
        Goals.calculate_goal_performance(user.id, :earnings, :week, ~D[2023-05-01])

      assert performance.performance_amount == 1_000
      assert Decimal.to_float(performance.performance_percent) == 1
    end

    test "Calculates monthly performance correctly" do
      user =
        Factory.create_user(%{
          timezone: "America/Los_Angeles"
        })

      _goal = Factory.create_default_goal(user.id, :earnings, :month, ~D[2023-04-01], 1_000)

      _activity_w0 = Factory.create_work_activity(user, ~D[2023-03-31], 300)
      _activity_w1_1 = Factory.create_work_activity(user, ~D[2023-04-01], 800)
      _activity_w1_2 = Factory.create_work_activity(user, ~D[2023-04-30], 200)
      _activity_w2 = Factory.create_work_activity(user, ~D[2023-05-01], 200)

      Earnings.update_timespans_and_allocations_for_user_workday(user, ~D[2023-03-31])
      Earnings.update_timespans_and_allocations_for_user_workday(user, ~D[2023-04-01])
      Earnings.update_timespans_and_allocations_for_user_workday(user, ~D[2023-04-30])
      Earnings.update_timespans_and_allocations_for_user_workday(user, ~D[2023-05-01])

      {:not_calculated, :no_goal_available} =
        Goals.calculate_goal_performance(user.id, :earnings, :month, ~D[2023-03-01])

      {:ok, performance, _goal} =
        Goals.calculate_goal_performance(user.id, :earnings, :month, ~D[2023-04-01])

      assert performance.performance_amount == 1_000
      assert Decimal.to_float(performance.performance_percent) == 1

      {:ok, performance, _goal} =
        Goals.calculate_goal_performance(user.id, :earnings, :month, ~D[2023-05-01])

      assert performance.performance_amount == 200
      assert Decimal.to_float(performance.performance_percent) == 0.2

      _goal = Factory.create_default_goal(user.id, :earnings, :month, ~D[2023-03-01], 500)

      {:ok, performance, _goal} =
        Goals.calculate_goal_performance(user.id, :earnings, :month, ~D[2023-03-01])

      assert performance.performance_amount == 300
      assert Decimal.to_float(performance.performance_percent) == 0.6

      {:ok, performance, _goal} =
        Goals.calculate_goal_performance(user.id, :earnings, :month, ~D[2023-04-01])

      assert performance.performance_amount == 1_000
      assert Decimal.to_float(performance.performance_percent) == 1
    end
  end

  defp for_compare(goals) do
    goals
    |> List.wrap()
    |> Enum.map(fn g ->
      %{
        type: g.type,
        frequency: g.frequency,
        sub_frequency: g.sub_frequency,
        amount: g.amount,
        start_date: g.start_date
      }
    end)
    |> Enum.sort_by(fn g ->
      "#{g.type}#{g.start_date}#{g.frequency}#{g.sub_frequency}#{g.amount}"
    end)
  end

  defp get_utc_date(%NaiveDateTime{} = local_dtm, timezone) do
    DateTime.from_naive!(local_dtm, timezone)
    |> DateTime.shift_zone!("Etc/UTC")
  end
end
