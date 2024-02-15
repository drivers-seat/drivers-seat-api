defmodule DriversSeatCoopWeb.UserPayPerformanceControllerTest do
  use DriversSeatCoopWeb.ConnCase, async: true
  alias DriversSeatCoop.Accounts.User
  alias DriversSeatCoop.Earnings

  setup %{conn: conn} do
    user =
      Factory.create_user(%{
        timezone: "America/Los_Angeles"
      })

    conn =
      put_req_header(conn, "accept", "application/json")
      |> TestHelpers.put_auth_header(user)

    {:ok, conn: conn, user: user}
  end

  describe "show user metrics" do
    test "renders metrics for user with no data", %{conn: conn} do
      conn =
        get(conn, Routes.earnings_path(conn, :summary), %{
          work_date_start: ~D[2021-11-02],
          work_date_end: ~D[2021-11-10]
        })

      # a brand new user will have no data
      assert %{
               "cents_average_hourly_gross" => 0,
               "cents_average_hourly_net" => 0,
               "cents_earnings_gross" => 0,
               "cents_earnings_net" => 0,
               "cents_expenses_deductible" => 0,
               "cents_expenses_mileage" => 0,
               "cents_pay" => 0,
               "cents_promotion" => 0,
               "cents_tip" => 0,
               "miles_total" => 0,
               "seconds_p3" => 0,
               "seconds_total" => 0,
               "tasks_total" => 0,
               "work_date_start" => "2021-11-02",
               "work_date_end" => "2021-11-10",
               "by_employer" => []
             } == json_response(conn, 200)["data"]
    end

    test "renders metrics for user with data", %{conn: conn, user: user} do
      # ignored expense

      expense_0 = 8888
      expense_1 = 2222
      expense_2 = 444

      Factory.create_expense(%{
        category: "Gas",
        date: ~D[2021-11-01],
        money: expense_0,
        user_id: user.id
      })

      Factory.create_expense(%{
        category: "Food and Drinks",
        date: ~D[2021-11-01],
        money: expense_1,
        user_id: user.id
      })

      Factory.create_expense(%{
        category: "Food and Drinks",
        date: ~D[2021-11-02],
        money: expense_2,
        user_id: user.id
      })

      employer_1 = "Uber"
      pay_1 = 700
      tip_1 = 100
      bonus_1 = 200
      earnings_1 = pay_1 + tip_1 + bonus_1
      hours_1 = 2
      irs_expense_1 = 560

      activity1_start_time = get_utc_date(~N[2021-11-01T11:30:00Z], user.timezone)
      activity1_end_time = get_utc_date(~N[2021-11-01T13:30:00Z], user.timezone)

      Factory.create_activity(user.id, %{
        "timezone" => user.timezone,
        "employer" => employer_1,
        "duration" => DateTime.diff(activity1_end_time, activity1_start_time),
        "distance" => 10.0,
        "earning_type" => "work",
        "status" => "completed",
        "num_tasks" => 3,
        "start_date" => activity1_start_time,
        "end_date" => activity1_end_time,
        "pay" => "#{pay_1 / 100}",
        "tips" => "#{tip_1 / 100}",
        "bonus" => "#{bonus_1 / 100}",
        "total" => "#{earnings_1 / 100}"
      })

      employer_2 = "Lyft"
      pay_2 = 800
      tip_2 = 300
      bonus_2 = 500
      earnings_2 = pay_2 + tip_2 + bonus_2
      hours_2 = 10
      irs_expense_2 = 1120

      activity2_start_time = get_utc_date(~N[2021-11-02T11:30:00Z], user.timezone)
      activity2_end_time = get_utc_date(~N[2021-11-02T21:30:00Z], user.timezone)

      Factory.create_activity(user.id, %{
        "timezone" => user.timezone,
        "employer" => employer_2,
        "duration" => DateTime.diff(activity2_end_time, activity2_start_time),
        "distance" => 20.0,
        "earning_type" => "work",
        "status" => "completed",
        "num_tasks" => 8,
        "start_date" => activity2_start_time,
        "end_date" => activity2_end_time,
        "pay" => "#{pay_2 / 100}",
        "tips" => "#{tip_2 / 100}",
        "bonus" => "#{bonus_2 / 100}",
        "total" => "#{earnings_2 / 100}"
      })

      employer_3 = employer_1
      pay_3 = 200
      tip_3 = 350
      bonus_3 = 150
      earnings_3 = pay_3 + tip_3 + bonus_3
      hours_3 = 3
      irs_expense_3 = 280

      activity3_start_time = get_utc_date(~N[2021-11-02T06:30:00Z], user.timezone)
      activity3_end_time = get_utc_date(~N[2021-11-02T09:30:00Z], user.timezone)

      Factory.create_activity(user.id, %{
        "timezone" => user.timezone,
        "employer" => employer_3,
        "duration" => DateTime.diff(activity3_end_time, activity3_start_time),
        "distance" => 5.0,
        "earning_type" => "work",
        "status" => "completed",
        "num_tasks" => 4,
        "start_date" => activity3_start_time,
        "end_date" => activity3_end_time,
        "pay" => "#{pay_3 / 100}",
        "tips" => "#{tip_3 / 100}",
        "bonus" => "#{bonus_3 / 100}",
        "total" => "#{earnings_3 / 100}"
      })

      Earnings.update_timespans_and_allocations_for_user_workday(
        user,
        ~D[2021-11-01],
        "user_facing"
      )

      Earnings.update_timespans_and_allocations_for_user_workday(
        user,
        ~D[2021-11-02],
        "user_facing"
      )

      conn =
        get(conn, Routes.earnings_path(conn, :summary), %{
          work_date_start: ~D[2021-11-01],
          work_date_end: ~D[2021-11-10]
        })

      total_hours = hours_1 + hours_2 + hours_3
      total_earnings = earnings_1 + earnings_2 + earnings_3
      total_expenses_mileage = irs_expense_1 + irs_expense_2 + irs_expense_3
      total_expenses_deductible = expense_0 + expense_1 + expense_2
      total_expenses = total_expenses_mileage + total_expenses_deductible
      cents_average_hourly_gross = total_earnings / total_hours
      cents_average_hourly_net = (total_earnings - total_expenses) / total_hours

      expected_employers =
        [
          %{
            "employer" => employer_2,
            "cents_pay" => pay_2,
            "cents_promotion" => bonus_2,
            "cents_tip" => tip_2,
            "seconds_p3" => hours_2 * 60 * 60,
            "seconds_total" => hours_2 * 60 * 60,
            "tasks_total" => 8
          },
          %{
            "employer" => employer_1,
            "cents_pay" => pay_1 + pay_3,
            "cents_promotion" => bonus_1 + bonus_3,
            "cents_tip" => tip_1 + tip_3,
            "seconds_p3" => (hours_1 + hours_3) * 60 * 60,
            "seconds_total" => (hours_1 + hours_3) * 60 * 60,
            "tasks_total" => 7
          }
        ]
        |> Enum.sort_by(fn x -> Map.get(x, "employer") end)

      actual = json_response(conn, 200)["data"]

      actual_without_employers = Map.delete(actual, "by_employer")

      actual_employers =
        Map.get(actual, "by_employer")
        |> Enum.sort_by(fn x -> Map.get(x, "employer") end)

      assert %{
               "cents_average_hourly_gross" => round_number(cents_average_hourly_gross),
               "cents_average_hourly_net" => round_number(cents_average_hourly_net),
               "cents_earnings_gross" => total_earnings,
               "cents_earnings_net" => total_earnings - total_expenses,
               "cents_expenses_deductible" => total_expenses_deductible,
               "cents_expenses_mileage" => total_expenses_mileage,
               "cents_pay" => pay_1 + pay_2 + pay_3,
               "cents_promotion" => bonus_1 + bonus_2 + bonus_3,
               "cents_tip" => tip_1 + tip_2 + tip_3,
               "miles_total" => 35.0,
               "seconds_p3" => total_hours * 60 * 60,
               "seconds_total" => total_hours * 60 * 60,
               "tasks_total" => 15,
               "work_date_start" => "2021-11-01",
               "work_date_end" => "2021-11-10"
             } == actual_without_employers

      assert expected_employers == actual_employers
    end

    test "filter metrics by date", %{conn: conn, user: user} do
      expense_1 = 2222
      expense_2 = 444

      # filtered out due to date range
      Factory.create_expense(%{
        category: "Food and Drinks",
        date: ~D[2021-11-01],
        money: expense_1,
        user_id: user.id
      })

      Factory.create_expense(%{
        category: "Food and Drinks",
        date: ~D[2021-11-02],
        money: expense_2,
        user_id: user.id
      })

      activity1_start_time = get_utc_date(~N[2021-11-01T11:30:00Z], user.timezone)
      activity1_end_time = get_utc_date(~N[2021-11-01T13:30:00Z], user.timezone)

      employer = "Test Employer"
      pay_1 = 2222
      tip_1 = 1111
      bonus_1 = 3333
      earnings_1 = pay_1 + tip_1 + bonus_1

      Factory.create_activity(user.id, %{
        "timezone" => user.timezone,
        "employer" => employer,
        "duration" => DateTime.diff(activity1_end_time, activity1_start_time),
        "distance" => 10.0,
        "earning_type" => "work",
        "status" => "completed",
        "num_tasks" => 3,
        "start_date" => activity1_start_time,
        "end_date" => activity1_end_time,
        "pay" => "#{pay_1 / 100}",
        "tips" => "#{tip_1 / 100}",
        "bonus" => "#{bonus_1 / 100}",
        "total" => "#{earnings_1 / 100}"
      })

      activity2_start_time = get_utc_date(~N[2021-11-02T06:30:00Z], user.timezone)
      activity2_end_time = get_utc_date(~N[2021-11-02T07:30:00Z], user.timezone)

      pay_2 = 4444
      tip_2 = 6666
      bonus_2 = 8888
      earnings_2 = pay_2 + tip_2 + bonus_2
      hours_2 = 1
      irs_expense_2 = 1120

      Factory.create_activity(user.id, %{
        "timezone" => user.timezone,
        "employer" => employer,
        "duration" => DateTime.diff(activity2_end_time, activity2_start_time),
        "distance" => 20.0,
        "earning_type" => "work",
        "status" => "completed",
        "num_tasks" => 3,
        "start_date" => activity2_start_time,
        "end_date" => activity2_end_time,
        "pay" => "#{pay_2 / 100}",
        "tips" => "#{tip_2 / 100}",
        "bonus" => "#{bonus_2 / 100}",
        "total" => "#{earnings_2 / 100}"
      })

      Earnings.update_timespans_and_allocations_for_user_workday(
        user,
        ~D[2021-11-01],
        "user_facing"
      )

      Earnings.update_timespans_and_allocations_for_user_workday(
        user,
        ~D[2021-11-02],
        "user_facing"
      )

      conn =
        get(conn, Routes.earnings_path(conn, :summary), %{
          work_date_start: ~D[2021-11-02],
          work_date_end: ~D[2021-11-10]
        })

      total_hours = hours_2
      total_earnings = earnings_2
      total_expenses = expense_2 + irs_expense_2
      cents_average_hourly_gross = total_earnings / total_hours
      cents_average_hourly_net = (total_earnings - total_expenses) / total_hours

      assert %{
               "cents_average_hourly_gross" => round_number(cents_average_hourly_gross),
               "cents_average_hourly_net" => round_number(cents_average_hourly_net),
               "cents_earnings_gross" => total_earnings,
               "cents_earnings_net" => total_earnings - total_expenses,
               "cents_expenses_deductible" => expense_2,
               "cents_expenses_mileage" => irs_expense_2,
               "cents_pay" => pay_2,
               "cents_promotion" => bonus_2,
               "cents_tip" => tip_2,
               "miles_total" => 20.0,
               "seconds_p3" => total_hours * 60 * 60,
               "seconds_total" => total_hours * 60 * 60,
               "tasks_total" => 3,
               "work_date_start" => "2021-11-02",
               "work_date_end" => "2021-11-10",
               "by_employer" => [
                 %{
                   "employer" => employer,
                   "cents_pay" => pay_2,
                   "cents_promotion" => bonus_2,
                   "cents_tip" => tip_2,
                   "seconds_p3" => hours_2 * 60 * 60,
                   "seconds_total" => hours_2 * 60 * 60,
                   "tasks_total" => 3
                 }
               ]
             } == json_response(conn, 200)["data"]
    end
  end

  describe "Get Latest Earnings by level" do
    test "returns properly for day", %{conn: conn, user: user} do
      expense_1 = 2222
      expense_2 = 444

      # filtered out due to date range
      Factory.create_expense(%{
        category: "Food and Drinks",
        date: ~D[2021-11-01],
        money: expense_1,
        user_id: user.id
      })

      Factory.create_expense(%{
        category: "Food and Drinks",
        date: ~D[2021-11-02],
        money: expense_2,
        user_id: user.id
      })

      activity1_start_time = get_utc_date(~N[2021-11-01T11:30:00Z], user.timezone)
      activity1_end_time = get_utc_date(~N[2021-11-01T13:30:00Z], user.timezone)

      employer = "Test Employer"
      pay_1 = 2222
      tip_1 = 1111
      bonus_1 = 3333
      earnings_1 = pay_1 + tip_1 + bonus_1
      _hours_1 = 2
      _irs_expense_1 = 560

      Factory.create_activity(user.id, %{
        "timezone" => user.timezone,
        "employer" => employer,
        "duration" => DateTime.diff(activity1_end_time, activity1_start_time),
        "distance" => 10.0,
        "earning_type" => "work",
        "status" => "completed",
        "num_tasks" => 3,
        "start_date" => activity1_start_time,
        "end_date" => activity1_end_time,
        "pay" => "#{pay_1 / 100}",
        "tips" => "#{tip_1 / 100}",
        "bonus" => "#{bonus_1 / 100}",
        "total" => "#{earnings_1 / 100}"
      })

      activity2_start_time = get_utc_date(~N[2021-11-02T06:30:00Z], user.timezone)
      activity2_end_time = get_utc_date(~N[2021-11-02T07:30:00Z], user.timezone)

      pay_2 = 4444
      tip_2 = 6666
      bonus_2 = 8888
      earnings_2 = pay_2 + tip_2 + bonus_2
      hours_2 = 1
      irs_expense_2 = 1120

      Factory.create_activity(user.id, %{
        "timezone" => user.timezone,
        "employer" => employer,
        "duration" => DateTime.diff(activity2_end_time, activity2_start_time),
        "distance" => 20.0,
        "earning_type" => "work",
        "status" => "completed",
        "num_tasks" => 3,
        "start_date" => activity2_start_time,
        "end_date" => activity2_end_time,
        "pay" => "#{pay_2 / 100}",
        "tips" => "#{tip_2 / 100}",
        "bonus" => "#{bonus_2 / 100}",
        "total" => "#{earnings_2 / 100}"
      })

      Earnings.update_timespans_and_allocations_for_user_workday(
        user,
        ~D[2021-11-01],
        "user_facing"
      )

      Earnings.update_timespans_and_allocations_for_user_workday(
        user,
        ~D[2021-11-02],
        "user_facing"
      )

      conn = get(conn, Routes.earnings_path(conn, :summary_latest, "day"))

      total_hours = hours_2
      total_earnings = earnings_2
      total_expenses = expense_2 + irs_expense_2
      cents_average_hourly_gross = total_earnings / total_hours
      cents_average_hourly_net = (total_earnings - total_expenses) / total_hours

      assert %{
               "cents_average_hourly_gross" => round_number(cents_average_hourly_gross),
               "cents_average_hourly_net" => round_number(cents_average_hourly_net),
               "cents_earnings_gross" => total_earnings,
               "cents_earnings_net" => total_earnings - total_expenses,
               "cents_expenses_deductible" => expense_2,
               "cents_expenses_mileage" => irs_expense_2,
               "cents_pay" => pay_2,
               "cents_promotion" => bonus_2,
               "cents_tip" => tip_2,
               "miles_total" => 20.0,
               "seconds_p3" => total_hours * 60 * 60,
               "seconds_total" => total_hours * 60 * 60,
               "tasks_total" => 3,
               "work_date_start" => "2021-11-02",
               "work_date_end" => "2021-11-02",
               "by_employer" => [
                 %{
                   "employer" => employer,
                   "cents_pay" => pay_2,
                   "cents_promotion" => bonus_2,
                   "cents_tip" => tip_2,
                   "seconds_p3" => hours_2 * 60 * 60,
                   "seconds_total" => hours_2 * 60 * 60,
                   "tasks_total" => 3
                 }
               ]
             } == json_response(conn, 200)["data"]
    end

    test "returns properly for week", %{conn: conn, user: user} do
      expense_1 = 2222
      expense_2 = 444

      # filtered out due to date range
      Factory.create_expense(%{
        category: "Food and Drinks",
        date: ~D[2021-11-01],
        money: expense_1,
        user_id: user.id
      })

      Factory.create_expense(%{
        category: "Food and Drinks",
        date: ~D[2021-11-02],
        money: expense_2,
        user_id: user.id
      })

      activity1_start_time = get_utc_date(~N[2021-11-01T11:30:00Z], user.timezone)
      activity1_end_time = get_utc_date(~N[2021-11-01T13:30:00Z], user.timezone)

      employer = "Test Employer"
      pay_1 = 2222
      tip_1 = 1111
      bonus_1 = 3333
      earnings_1 = pay_1 + tip_1 + bonus_1
      hours_1 = 2
      irs_expense_1 = 560

      Factory.create_activity(user.id, %{
        "timezone" => user.timezone,
        "employer" => employer,
        "duration" => DateTime.diff(activity1_end_time, activity1_start_time),
        "distance" => 10.0,
        "earning_type" => "work",
        "status" => "completed",
        "num_tasks" => 3,
        "start_date" => activity1_start_time,
        "end_date" => activity1_end_time,
        "pay" => "#{pay_1 / 100}",
        "tips" => "#{tip_1 / 100}",
        "bonus" => "#{bonus_1 / 100}",
        "total" => "#{earnings_1 / 100}"
      })

      activity2_start_time = get_utc_date(~N[2021-11-02T06:30:00Z], user.timezone)
      activity2_end_time = get_utc_date(~N[2021-11-02T07:30:00Z], user.timezone)

      pay_2 = 4444
      tip_2 = 6666
      bonus_2 = 8888
      earnings_2 = pay_2 + tip_2 + bonus_2
      hours_2 = 1
      irs_expense_2 = 1120

      Factory.create_activity(user.id, %{
        "timezone" => user.timezone,
        "employer" => employer,
        "duration" => DateTime.diff(activity2_end_time, activity2_start_time),
        "distance" => 20.0,
        "earning_type" => "work",
        "status" => "completed",
        "num_tasks" => 3,
        "start_date" => activity2_start_time,
        "end_date" => activity2_end_time,
        "pay" => "#{pay_2 / 100}",
        "tips" => "#{tip_2 / 100}",
        "bonus" => "#{bonus_2 / 100}",
        "total" => "#{earnings_2 / 100}"
      })

      Earnings.update_timespans_and_allocations_for_user_workday(
        user,
        ~D[2021-11-01],
        "user_facing"
      )

      Earnings.update_timespans_and_allocations_for_user_workday(
        user,
        ~D[2021-11-02],
        "user_facing"
      )

      conn = get(conn, Routes.earnings_path(conn, :summary_latest, "week"))

      total_hours = hours_1 + hours_2
      total_earnings = earnings_1 + earnings_2
      total_expenses = expense_1 + expense_2 + irs_expense_1 + irs_expense_2
      cents_average_hourly_gross = total_earnings / total_hours
      cents_average_hourly_net = (total_earnings - total_expenses) / total_hours

      assert %{
               "cents_average_hourly_gross" => round_number(cents_average_hourly_gross),
               "cents_average_hourly_net" => round_number(cents_average_hourly_net),
               "cents_earnings_gross" => total_earnings,
               "cents_earnings_net" => total_earnings - total_expenses,
               "cents_expenses_deductible" => expense_1 + expense_2,
               "cents_expenses_mileage" => irs_expense_1 + irs_expense_2,
               "cents_pay" => pay_1 + pay_2,
               "cents_promotion" => bonus_1 + bonus_2,
               "cents_tip" => tip_1 + tip_2,
               "miles_total" => 30.0,
               "seconds_p3" => total_hours * 60 * 60,
               "seconds_total" => total_hours * 60 * 60,
               "tasks_total" => 6,
               "work_date_start" => "2021-11-01",
               "work_date_end" => "2021-11-07",
               "by_employer" => [
                 %{
                   "employer" => employer,
                   "cents_pay" => pay_1 + pay_2,
                   "cents_promotion" => bonus_1 + bonus_2,
                   "cents_tip" => tip_1 + tip_2,
                   "seconds_p3" => (hours_1 + hours_2) * 60 * 60,
                   "seconds_total" => (hours_1 + hours_2) * 60 * 60,
                   "tasks_total" => 6
                 }
               ]
             } == json_response(conn, 200)["data"]
    end

    test "returns properly for month", %{conn: conn, user: user} do
      expense_1 = 2222
      expense_2 = 444

      # filtered out due to date range
      Factory.create_expense(%{
        category: "Food and Drinks",
        date: ~D[2021-11-01],
        money: expense_1,
        user_id: user.id
      })

      Factory.create_expense(%{
        category: "Food and Drinks",
        date: ~D[2021-11-02],
        money: expense_2,
        user_id: user.id
      })

      activity1_start_time = get_utc_date(~N[2021-11-01T11:30:00Z], user.timezone)
      activity1_end_time = get_utc_date(~N[2021-11-01T13:30:00Z], user.timezone)

      employer = "Test Employer"
      pay_1 = 2222
      tip_1 = 1111
      bonus_1 = 3333
      earnings_1 = pay_1 + tip_1 + bonus_1
      hours_1 = 2
      irs_expense_1 = 560

      Factory.create_activity(user.id, %{
        "timezone" => user.timezone,
        "employer" => employer,
        "duration" => DateTime.diff(activity1_end_time, activity1_start_time),
        "distance" => 10.0,
        "earning_type" => "work",
        "status" => "completed",
        "num_tasks" => 3,
        "start_date" => activity1_start_time,
        "end_date" => activity1_end_time,
        "pay" => "#{pay_1 / 100}",
        "tips" => "#{tip_1 / 100}",
        "bonus" => "#{bonus_1 / 100}",
        "total" => "#{earnings_1 / 100}"
      })

      activity2_start_time = get_utc_date(~N[2021-11-02T06:30:00Z], user.timezone)
      activity2_end_time = get_utc_date(~N[2021-11-02T07:30:00Z], user.timezone)

      pay_2 = 4444
      tip_2 = 6666
      bonus_2 = 8888
      earnings_2 = pay_2 + tip_2 + bonus_2
      hours_2 = 1
      irs_expense_2 = 1120

      Factory.create_activity(user.id, %{
        "timezone" => user.timezone,
        "employer" => employer,
        "duration" => DateTime.diff(activity2_end_time, activity2_start_time),
        "distance" => 20.0,
        "earning_type" => "work",
        "status" => "completed",
        "num_tasks" => 3,
        "start_date" => activity2_start_time,
        "end_date" => activity2_end_time,
        "pay" => "#{pay_2 / 100}",
        "tips" => "#{tip_2 / 100}",
        "bonus" => "#{bonus_2 / 100}",
        "total" => "#{earnings_2 / 100}"
      })

      Earnings.update_timespans_and_allocations_for_user_workday(
        user,
        ~D[2021-11-01],
        "user_facing"
      )

      Earnings.update_timespans_and_allocations_for_user_workday(
        user,
        ~D[2021-11-02],
        "user_facing"
      )

      conn = get(conn, Routes.earnings_path(conn, :summary_latest, "month"))

      total_hours = hours_1 + hours_2
      total_earnings = earnings_1 + earnings_2
      total_expenses = expense_1 + expense_2 + irs_expense_1 + irs_expense_2
      cents_average_hourly_gross = total_earnings / total_hours
      cents_average_hourly_net = (total_earnings - total_expenses) / total_hours

      assert %{
               "cents_average_hourly_gross" => round_number(cents_average_hourly_gross),
               "cents_average_hourly_net" => round_number(cents_average_hourly_net),
               "cents_earnings_gross" => total_earnings,
               "cents_earnings_net" => total_earnings - total_expenses,
               "cents_expenses_deductible" => expense_1 + expense_2,
               "cents_expenses_mileage" => irs_expense_1 + irs_expense_2,
               "cents_pay" => pay_1 + pay_2,
               "cents_promotion" => bonus_1 + bonus_2,
               "cents_tip" => tip_1 + tip_2,
               "miles_total" => 30.0,
               "seconds_p3" => total_hours * 60 * 60,
               "seconds_total" => total_hours * 60 * 60,
               "tasks_total" => 6,
               "work_date_start" => "2021-11-01",
               "work_date_end" => "2021-11-30",
               "by_employer" => [
                 %{
                   "employer" => employer,
                   "cents_pay" => pay_1 + pay_2,
                   "cents_promotion" => bonus_1 + bonus_2,
                   "cents_tip" => tip_1 + tip_2,
                   "seconds_p3" => (hours_1 + hours_2) * 60 * 60,
                   "seconds_total" => (hours_1 + hours_2) * 60 * 60,
                   "tasks_total" => 6
                 }
               ]
             } == json_response(conn, 200)["data"]
    end

    test "returns properly for year", %{conn: conn, user: user} do
      expense_1 = 2222
      expense_2 = 444

      # filtered out due to date range
      Factory.create_expense(%{
        category: "Food and Drinks",
        date: ~D[2021-11-01],
        money: expense_1,
        user_id: user.id
      })

      Factory.create_expense(%{
        category: "Food and Drinks",
        date: ~D[2021-11-02],
        money: expense_2,
        user_id: user.id
      })

      activity1_start_time = get_utc_date(~N[2021-11-01T11:30:00Z], user.timezone)
      activity1_end_time = get_utc_date(~N[2021-11-01T13:30:00Z], user.timezone)

      employer = "Test Employer"
      pay_1 = 2222
      tip_1 = 1111
      bonus_1 = 3333
      earnings_1 = pay_1 + tip_1 + bonus_1
      hours_1 = 2
      irs_expense_1 = 560

      Factory.create_activity(user.id, %{
        "timezone" => user.timezone,
        "employer" => employer,
        "duration" => DateTime.diff(activity1_end_time, activity1_start_time),
        "distance" => 10.0,
        "earning_type" => "work",
        "status" => "completed",
        "num_tasks" => 3,
        "start_date" => activity1_start_time,
        "end_date" => activity1_end_time,
        "pay" => "#{pay_1 / 100}",
        "tips" => "#{tip_1 / 100}",
        "bonus" => "#{bonus_1 / 100}",
        "total" => "#{earnings_1 / 100}"
      })

      activity2_start_time = get_utc_date(~N[2021-11-02T06:30:00Z], user.timezone)
      activity2_end_time = get_utc_date(~N[2021-11-02T07:30:00Z], user.timezone)

      pay_2 = 4444
      tip_2 = 6666
      bonus_2 = 8888
      earnings_2 = pay_2 + tip_2 + bonus_2
      hours_2 = 1
      irs_expense_2 = 1120

      Factory.create_activity(user.id, %{
        "timezone" => user.timezone,
        "employer" => employer,
        "duration" => DateTime.diff(activity2_end_time, activity2_start_time),
        "distance" => 20.0,
        "earning_type" => "work",
        "status" => "completed",
        "num_tasks" => 3,
        "start_date" => activity2_start_time,
        "end_date" => activity2_end_time,
        "pay" => "#{pay_2 / 100}",
        "tips" => "#{tip_2 / 100}",
        "bonus" => "#{bonus_2 / 100}",
        "total" => "#{earnings_2 / 100}"
      })

      Earnings.update_timespans_and_allocations_for_user_workday(
        user,
        ~D[2021-11-01],
        "user_facing"
      )

      Earnings.update_timespans_and_allocations_for_user_workday(
        user,
        ~D[2021-11-02],
        "user_facing"
      )

      conn = get(conn, Routes.earnings_path(conn, :summary_latest, "year"))

      total_hours = hours_1 + hours_2
      total_earnings = earnings_1 + earnings_2
      total_expenses = expense_1 + expense_2 + irs_expense_1 + irs_expense_2
      cents_average_hourly_gross = total_earnings / total_hours
      cents_average_hourly_net = (total_earnings - total_expenses) / total_hours

      assert %{
               "cents_average_hourly_gross" => round_number(cents_average_hourly_gross),
               "cents_average_hourly_net" => round_number(cents_average_hourly_net),
               "cents_earnings_gross" => total_earnings,
               "cents_earnings_net" => total_earnings - total_expenses,
               "cents_expenses_deductible" => expense_1 + expense_2,
               "cents_expenses_mileage" => irs_expense_1 + irs_expense_2,
               "cents_pay" => pay_1 + pay_2,
               "cents_promotion" => bonus_1 + bonus_2,
               "cents_tip" => tip_1 + tip_2,
               "miles_total" => 30.0,
               "seconds_p3" => total_hours * 60 * 60,
               "seconds_total" => total_hours * 60 * 60,
               "tasks_total" => 6,
               "work_date_start" => "2021-01-01",
               "work_date_end" => "2021-12-31",
               "by_employer" => [
                 %{
                   "employer" => employer,
                   "cents_pay" => pay_1 + pay_2,
                   "cents_promotion" => bonus_1 + bonus_2,
                   "cents_tip" => tip_1 + tip_2,
                   "seconds_p3" => (hours_1 + hours_2) * 60 * 60,
                   "seconds_total" => (hours_1 + hours_2) * 60 * 60,
                   "tasks_total" => 6
                 }
               ]
             } == json_response(conn, 200)["data"]
    end

    test "returns properly when no data is available - day", %{conn: conn, user: user} do
      d = User.datetime_to_working_day(DateTime.utc_now(), user)

      conn = get(conn, Routes.earnings_path(conn, :summary_latest, "day"))

      assert %{
               "cents_average_hourly_gross" => 0,
               "cents_average_hourly_net" => 0,
               "cents_earnings_gross" => 0,
               "cents_earnings_net" => 0,
               "cents_expenses_deductible" => 0,
               "cents_expenses_mileage" => 0,
               "cents_pay" => 0,
               "cents_promotion" => 0,
               "cents_tip" => 0,
               "miles_total" => 0.0,
               "seconds_p3" => 0,
               "seconds_total" => 0,
               "tasks_total" => 0,
               "work_date_start" => "#{d}",
               "work_date_end" => "#{d}",
               "by_employer" => []
             } == json_response(conn, 200)["data"]
    end
  end

  defp round_number(number) do
    number
    |> Decimal.from_float()
    |> Decimal.round()
    |> Decimal.to_integer()
  end

  defp get_utc_date(%NaiveDateTime{} = local_dtm, timezone) do
    DateTime.from_naive!(local_dtm, timezone)
    |> DateTime.shift_zone!("Etc/UTC")
  end
end
