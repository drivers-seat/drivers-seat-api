defmodule DriversSeatCoop.NotificationsTest do
  alias DriversSeatCoop.Util.DateTimeUtil
  use DriversSeatCoop.DataCase, async: true
  use Oban.Testing, repo: DriversSeatCoop.Repo

  alias DriversSeatCoop.Notifications.Oban.GoalPerformanceCelebration
  alias DriversSeatCoop.Notifications.Oban.GoalPerformanceUpdate

  @user_attr %{timezone: "Etc/UTC", is_demo_account: true}

  describe "GoalsPerformanceCelebration" do
    test "only sends if 100% + performance" do
      goal_amt = 100_000

      user = Factory.create_user(@user_attr)
      goal = Factory.create_default_goal(user.id, :earnings, :week, ~D[2023-01-01], goal_amt)

      today = Date.utc_today()

      {start_0, _end_0} = DateTimeUtil.get_time_window_for_date(today, :week)
      {start_1, _end_1} = DateTimeUtil.get_time_window_for_date(Date.add(start_0, -1), :week)
      {start_2, _end_2} = DateTimeUtil.get_time_window_for_date(Date.add(start_1, -1), :week)

      perf_0 = Factory.create_goal_measurement(goal, start_0, goal_amt)
      _perf_1 = Factory.create_goal_measurement(goal, start_1, goal_amt - 2_000)
      perf_2 = Factory.create_goal_measurement(goal, start_2, goal_amt + 3_000)

      expected =
        [
          for_compare(goal, perf_0, true),
          for_compare(goal, perf_2, false)
        ]
        |> Enum.sort_by(fn x -> x.window_date end, Date)

      actual =
        GoalPerformanceCelebration.get_qualified_measurements(:week, 3)
        |> Enum.sort_by(fn x -> x.window_date end, Date)

      assert expected == actual
    end

    test "pulls performance metrics only for the requested window" do
      goal_amt = 100_000

      user = Factory.create_user(@user_attr)
      goal = Factory.create_default_goal(user.id, :earnings, :week, ~D[2023-01-01], goal_amt)

      today = Date.utc_today()

      {start_0, _end_0} = DateTimeUtil.get_time_window_for_date(today, :week)
      {start_1, _end_1} = DateTimeUtil.get_time_window_for_date(Date.add(start_0, -1), :week)
      {start_2, _end_2} = DateTimeUtil.get_time_window_for_date(Date.add(start_1, -1), :week)
      {start_3, _end_3} = DateTimeUtil.get_time_window_for_date(Date.add(start_2, -1), :week)
      {start_4, _end_4} = DateTimeUtil.get_time_window_for_date(Date.add(start_3, -1), :week)
      {start_5, _end_5} = DateTimeUtil.get_time_window_for_date(Date.add(start_4, -1), :week)

      perf_0 = Factory.create_goal_measurement(goal, start_0, goal_amt)
      _perf_1 = Factory.create_goal_measurement(goal, start_1, goal_amt - 2_000)
      perf_2 = Factory.create_goal_measurement(goal, start_2, goal_amt + 3_000)
      _perf_3 = Factory.create_goal_measurement(goal, start_3, goal_amt + 3_000)
      _perf_4 = Factory.create_goal_measurement(goal, start_4, goal_amt + 3_000)
      _perf_5 = Factory.create_goal_measurement(goal, start_5, goal_amt + 3_000)

      expected =
        [
          for_compare(goal, perf_0, true),
          for_compare(goal, perf_2, false)
        ]
        |> Enum.sort_by(fn x -> x.window_date end, Date)

      actual =
        GoalPerformanceCelebration.get_qualified_measurements(:week, 3)
        |> Enum.sort_by(fn x -> x.window_date end, Date)

      assert expected == actual
    end

    test "only covers the last 2 weeks" do
      goal_amt = 100_000

      user = Factory.create_user(@user_attr)
      goal = Factory.create_default_goal(user.id, :earnings, :week, ~D[2023-01-01], goal_amt)

      today = Date.utc_today()

      {start_0, _end_0} = DateTimeUtil.get_time_window_for_date(today, :week)
      {start_1, _end_1} = DateTimeUtil.get_time_window_for_date(Date.add(start_0, -1), :week)
      {start_2, _end_2} = DateTimeUtil.get_time_window_for_date(Date.add(start_1, -1), :week)
      {start_3, _end_3} = DateTimeUtil.get_time_window_for_date(Date.add(start_2, -1), :week)
      {start_4, _end_4} = DateTimeUtil.get_time_window_for_date(Date.add(start_3, -1), :week)
      {start_5, _end_5} = DateTimeUtil.get_time_window_for_date(Date.add(start_4, -1), :week)

      perf_0 = Factory.create_goal_measurement(goal, start_0, goal_amt)
      perf_1 = Factory.create_goal_measurement(goal, start_1, goal_amt - 2_000)
      perf_2 = Factory.create_goal_measurement(goal, start_2, goal_amt + 3_000)
      perf_3 = Factory.create_goal_measurement(goal, start_3, goal_amt + 3_000)
      perf_4 = Factory.create_goal_measurement(goal, start_4, goal_amt + 3_000)
      perf_5 = Factory.create_goal_measurement(goal, start_5, goal_amt + 3_000)

      GoalPerformanceCelebration.schedule_jobs()

      assert_enqueued(worker: GoalPerformanceCelebration, args: for_compare(goal, perf_0, true))
      refute_enqueued(worker: GoalPerformanceCelebration, args: for_compare(goal, perf_1, false))

      refute_enqueued(worker: GoalPerformanceCelebration, args: for_compare(goal, perf_2, false))
      refute_enqueued(worker: GoalPerformanceCelebration, args: for_compare(goal, perf_3, false))
      refute_enqueued(worker: GoalPerformanceCelebration, args: for_compare(goal, perf_4, false))
      refute_enqueued(worker: GoalPerformanceCelebration, args: for_compare(goal, perf_5, false))
    end

    test "only covers the last 2 months" do
      goal_amt = 100_000

      user = Factory.create_user(@user_attr)
      goal = Factory.create_default_goal(user.id, :earnings, :month, ~D[2023-01-01], goal_amt)
      today = Date.utc_today()

      {start_0, _end_0} = DateTimeUtil.get_time_window_for_date(today, :month)
      {start_1, _end_1} = DateTimeUtil.get_time_window_for_date(Date.add(start_0, -1), :month)
      {start_2, _end_2} = DateTimeUtil.get_time_window_for_date(Date.add(start_1, -1), :month)
      {start_3, _end_3} = DateTimeUtil.get_time_window_for_date(Date.add(start_2, -1), :month)
      {start_4, _end_4} = DateTimeUtil.get_time_window_for_date(Date.add(start_3, -1), :month)
      {start_5, _end_5} = DateTimeUtil.get_time_window_for_date(Date.add(start_4, -1), :month)

      perf_0 = Factory.create_goal_measurement(goal, start_0, goal_amt)
      perf_1 = Factory.create_goal_measurement(goal, start_1, goal_amt - 2_000)
      perf_2 = Factory.create_goal_measurement(goal, start_2, goal_amt + 3_000)
      perf_3 = Factory.create_goal_measurement(goal, start_3, goal_amt + 3_000)
      perf_4 = Factory.create_goal_measurement(goal, start_4, goal_amt + 3_000)
      perf_5 = Factory.create_goal_measurement(goal, start_5, goal_amt + 3_000)

      GoalPerformanceCelebration.schedule_jobs()

      assert_enqueued(worker: GoalPerformanceCelebration, args: for_compare(goal, perf_0, true))
      refute_enqueued(worker: GoalPerformanceCelebration, args: for_compare(goal, perf_1, false))

      refute_enqueued(worker: GoalPerformanceCelebration, args: for_compare(goal, perf_2, false))
      refute_enqueued(worker: GoalPerformanceCelebration, args: for_compare(goal, perf_3, false))
      refute_enqueued(worker: GoalPerformanceCelebration, args: for_compare(goal, perf_4, false))
      refute_enqueued(worker: GoalPerformanceCelebration, args: for_compare(goal, perf_5, false))
    end

    test "only covers the last 5 days" do
      goal_amt = 100_000

      user = Factory.create_user(@user_attr)
      goal = Factory.create_default_goal(user.id, :earnings, :day, ~D[2023-01-01], goal_amt)
      today = Date.utc_today()

      {start_0, _end_0} = DateTimeUtil.get_time_window_for_date(today, :day)
      {start_1, _end_1} = DateTimeUtil.get_time_window_for_date(Date.add(start_0, -1), :day)
      {start_2, _end_2} = DateTimeUtil.get_time_window_for_date(Date.add(start_1, -1), :day)
      {start_3, _end_3} = DateTimeUtil.get_time_window_for_date(Date.add(start_2, -1), :day)
      {start_4, _end_4} = DateTimeUtil.get_time_window_for_date(Date.add(start_3, -1), :day)
      {start_5, _end_5} = DateTimeUtil.get_time_window_for_date(Date.add(start_4, -1), :day)
      {start_6, _end_6} = DateTimeUtil.get_time_window_for_date(Date.add(start_5, -1), :day)
      {start_7, _end_7} = DateTimeUtil.get_time_window_for_date(Date.add(start_6, -1), :day)

      perf_0 = Factory.create_goal_measurement(goal, start_0, goal_amt)
      perf_1 = Factory.create_goal_measurement(goal, start_1, goal_amt - 2_000)
      perf_2 = Factory.create_goal_measurement(goal, start_2, goal_amt + 3_000)
      perf_3 = Factory.create_goal_measurement(goal, start_3, goal_amt + 3_000)
      perf_4 = Factory.create_goal_measurement(goal, start_4, goal_amt + 3_000)
      perf_5 = Factory.create_goal_measurement(goal, start_5, goal_amt + 3_000)
      perf_6 = Factory.create_goal_measurement(goal, start_6, goal_amt + 3_000)
      perf_7 = Factory.create_goal_measurement(goal, start_7, goal_amt + 3_000)

      GoalPerformanceCelebration.schedule_jobs()

      assert_enqueued(worker: GoalPerformanceCelebration, args: for_compare(goal, perf_0, true))
      refute_enqueued(worker: GoalPerformanceCelebration, args: for_compare(goal, perf_1, false))
      assert_enqueued(worker: GoalPerformanceCelebration, args: for_compare(goal, perf_2, false))
      assert_enqueued(worker: GoalPerformanceCelebration, args: for_compare(goal, perf_3, false))
      assert_enqueued(worker: GoalPerformanceCelebration, args: for_compare(goal, perf_4, false))

      refute_enqueued(worker: GoalPerformanceCelebration, args: for_compare(goal, perf_5, false))
      refute_enqueued(worker: GoalPerformanceCelebration, args: for_compare(goal, perf_6, false))
      refute_enqueued(worker: GoalPerformanceCelebration, args: for_compare(goal, perf_7, false))
    end

    defp for_compare(goal, meas, _is_current_window) do
      %{
        user_id: meas.user_id,
        type: goal.type,
        frequency: goal.frequency,
        window_date: meas.window_date,
        goal_amount_cents: goal.amount,
        performance_percent: Decimal.to_float(meas.performance_percent),
        performance_amount_cents: meas.performance_amount
      }
    end
  end

  describe "GoalPerformanceUpdate" do
    test "only sends if performance is >= 5% and < 100%" do
      goal_amt = 100_000

      u1 = Factory.create_user(@user_attr)
      u1_g1 = Factory.create_default_goal(u1.id, :earnings, :week, ~D[2023-01-01], goal_amt)

      u2 = Factory.create_user(@user_attr)
      u2_g1 = Factory.create_default_goal(u2.id, :earnings, :week, ~D[2023-01-01], goal_amt)

      u3 = Factory.create_user(@user_attr)
      u3_g1 = Factory.create_default_goal(u3.id, :earnings, :week, ~D[2023-01-01], goal_amt)

      u4 = Factory.create_user(@user_attr)
      u4_g1 = Factory.create_default_goal(u4.id, :earnings, :week, ~D[2023-01-01], goal_amt)

      u5 = Factory.create_user(@user_attr)
      u5_g1 = Factory.create_default_goal(u5.id, :earnings, :week, ~D[2023-01-01], goal_amt)

      u6 = Factory.create_user(@user_attr)
      u6_g1 = Factory.create_default_goal(u6.id, :earnings, :week, ~D[2023-01-01], goal_amt)

      today = Date.utc_today()

      {start, _end} = DateTimeUtil.get_time_window_for_date(today, :week)

      _u1_perf = Factory.create_goal_measurement(u1_g1, start, trunc(goal_amt * 0.04))
      u2_perf = Factory.create_goal_measurement(u2_g1, start, trunc(goal_amt * 0.05))
      u3_perf = Factory.create_goal_measurement(u3_g1, start, trunc(goal_amt * 0.3))
      u4_perf = Factory.create_goal_measurement(u4_g1, start, trunc(goal_amt * 0.99))
      _u5_perf = Factory.create_goal_measurement(u5_g1, start, trunc(goal_amt))
      _u6_perf = Factory.create_goal_measurement(u6_g1, start, trunc(goal_amt * 1.2))

      expected =
        [
          for_compare(u2_g1, u2_perf),
          for_compare(u3_g1, u3_perf),
          for_compare(u4_g1, u4_perf)
        ]
        |> Enum.sort_by(fn x -> x.user_id end)

      actual =
        GoalPerformanceUpdate.get_qualified_measurements(:week)
        |> Enum.sort_by(fn x -> x.user_id end)

      assert expected == actual
    end

    test "only considers the current week window" do
      goal_amt = 100_000

      u1 = Factory.create_user(@user_attr)
      u1_g1 = Factory.create_default_goal(u1.id, :earnings, :week, ~D[2023-01-01], goal_amt)
      today = Date.utc_today()

      {start_0, _end} = DateTimeUtil.get_time_window_for_date(today, :week)
      {start_1, _end} = DateTimeUtil.get_time_window_for_date(Date.add(start_0, -1), :week)

      u1_perf_0 = Factory.create_goal_measurement(u1_g1, start_0, trunc(goal_amt * 0.4))
      _u1_perf_1 = Factory.create_goal_measurement(u1_g1, start_1, trunc(goal_amt * 0.5))

      expected = [
        for_compare(u1_g1, u1_perf_0)
      ]

      actual = GoalPerformanceUpdate.get_qualified_measurements(:week)

      assert expected == actual
    end

    test "only considers the current month window" do
      goal_amt = 100_000

      u1 = Factory.create_user(@user_attr)
      u1_g1 = Factory.create_default_goal(u1.id, :earnings, :month, ~D[2023-01-01], goal_amt)
      today = Date.utc_today()

      {start_0, _end} = DateTimeUtil.get_time_window_for_date(today, :month)
      {start_1, _end} = DateTimeUtil.get_time_window_for_date(Date.add(start_0, -1), :month)

      u1_perf_0 = Factory.create_goal_measurement(u1_g1, start_0, trunc(goal_amt * 0.4))
      _u1_perf_1 = Factory.create_goal_measurement(u1_g1, start_1, trunc(goal_amt * 0.5))

      expected = [
        for_compare(u1_g1, u1_perf_0)
      ]

      actual = GoalPerformanceUpdate.get_qualified_measurements(:month)

      assert expected == actual
    end

    test "schedules correctly based on weeks" do
      g_w_amt = 100_000
      g_m_amt = 500_000

      u1 = Factory.create_user(@user_attr)
      u1_gw = Factory.create_default_goal(u1.id, :earnings, :week, ~D[2023-01-01], g_w_amt)
      u1_gm = Factory.create_default_goal(u1.id, :earnings, :month, ~D[2023-01-01], g_m_amt)

      today = Date.utc_today()

      {start_week, _end} = DateTimeUtil.get_time_window_for_date(today, :week)
      {start_month, _end} = DateTimeUtil.get_time_window_for_date(today, :month)

      u1_perf_w = Factory.create_goal_measurement(u1_gw, start_week, trunc(g_w_amt * 0.6))
      u1_perf_m = Factory.create_goal_measurement(u1_gm, start_month, trunc(g_m_amt * 0.6))

      GoalPerformanceUpdate.perform(%Oban.Job{
        id: -1,
        args: %{
          "freq" => "week"
        }
      })

      assert_enqueued(
        worker: DriversSeatCoop.Notifications.Oban.GoalPerformanceUpdate,
        args: for_compare(u1_gw, u1_perf_w)
      )

      refute_enqueued(
        worker: DriversSeatCoop.Notifications.Oban.GoalPerformanceUpdate,
        args: for_compare(u1_gm, u1_perf_m)
      )
    end

    test "schedules correctly based on months" do
      g_w_amt = 100_000
      g_m_amt = 500_000

      u1 = Factory.create_user(@user_attr)
      u1_gw = Factory.create_default_goal(u1.id, :earnings, :week, ~D[2023-01-01], g_w_amt)
      u1_gm = Factory.create_default_goal(u1.id, :earnings, :month, ~D[2023-01-01], g_m_amt)

      today = Date.utc_today()

      {start_week, _end} = DateTimeUtil.get_time_window_for_date(today, :week)
      {start_month, _end} = DateTimeUtil.get_time_window_for_date(today, :month)

      u1_perf_w = Factory.create_goal_measurement(u1_gw, start_week, trunc(g_w_amt * 0.6))
      u1_perf_m = Factory.create_goal_measurement(u1_gm, start_month, trunc(g_m_amt * 0.6))

      GoalPerformanceUpdate.perform(%Oban.Job{
        id: -1,
        args: %{
          "freq" => "month"
        }
      })

      refute_enqueued(
        worker: DriversSeatCoop.Notifications.Oban.GoalPerformanceUpdate,
        args: for_compare(u1_gw, u1_perf_w)
      )

      assert_enqueued(
        worker: DriversSeatCoop.Notifications.Oban.GoalPerformanceUpdate,
        args: for_compare(u1_gm, u1_perf_m)
      )
    end

    defp for_compare(goal, meas) do
      %{
        user_id: meas.user_id,
        type: goal.type,
        frequency: goal.frequency,
        window_date: meas.window_date,
        goal_amount_cents: goal.amount,
        performance_percent: Decimal.to_float(meas.performance_percent),
        performance_amount_cents: meas.performance_amount
      }
    end
  end
end
