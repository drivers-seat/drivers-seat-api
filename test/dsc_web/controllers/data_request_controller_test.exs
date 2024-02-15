defmodule DriversSeatCoopWeb.DataRequestControllerTest do
  use DriversSeatCoopWeb.ConnCase
  use Oban.Testing, repo: DriversSeatCoop.Repo

  alias DriversSeatCoop.Earnings.Oban.ExportUserEarningsQuery
  alias DriversSeatCoop.Expenses.Oban.ExportUserExpensesQuery

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "create data_request" do
    test "enqueues export for expenses", %{conn: conn} do
      user = Factory.create_user(%{email: "test@rokkincat.com"})

      expense_1 =
        Factory.create_expense(%{
          user_id: user.id
        })

      expense_2 =
        Factory.create_expense(%{
          user_id: user.id,
          date: ~D[2019-03-01]
        })

      conn =
        conn
        |> TestHelpers.put_auth_header(user)
        |> post(Routes.data_request_path(conn, :create))

      assert %{"success" => true} = json_response(conn, 200)["data"]

      assert_enqueued(
        worker: ExportUserExpensesQuery,
        args: %{
          user_id: user.id,
          date_start: "#{Date.new!(expense_1.date.year, 1, 1)}",
          date_end: "#{Date.new!(expense_1.date.year, 12, 31)}"
        }
      )

      assert_enqueued(
        worker: ExportUserExpensesQuery,
        args: %{
          user_id: user.id,
          date_start: "#{Date.new!(expense_2.date.year, 1, 1)}",
          date_end: "#{Date.new!(expense_2.date.year, 12, 31)}"
        }
      )
    end

    test "enqueues export for earnings", %{conn: conn} do
      user = Factory.create_user(%{email: "test@rokkincat.com"})

      activity_1 =
        Factory.create_activity(%{
          "user_id" => user.id,
          "date" => ~U[2017-06-26T03:39:18Z]
        })

      activity_2 =
        Factory.create_activity(%{
          "user_id" => user.id,
          "date" => ~U[2021-06-26T03:39:18Z]
        })

      DriversSeatCoop.Earnings.update_timespans_and_allocations_for_user_workday(
        user,
        activity_1.working_day_start
      )

      DriversSeatCoop.Earnings.update_timespans_and_allocations_for_user_workday(
        user,
        activity_2.working_day_start
      )

      conn =
        conn
        |> TestHelpers.put_auth_header(user)
        |> post(Routes.data_request_path(conn, :create))

      assert %{"success" => true} = json_response(conn, 200)["data"]

      assert_enqueued(
        worker: ExportUserEarningsQuery,
        args: %{
          user_id: user.id,
          include_non_p3_time: true,
          date_start: "#{Date.new!(activity_1.working_day_start.year, 1, 1)}",
          date_end: "#{Date.new!(activity_1.working_day_start.year, 12, 31)}"
        }
      )

      assert_enqueued(
        worker: ExportUserEarningsQuery,
        args: %{
          user_id: user.id,
          include_non_p3_time: true,
          date_start: "#{Date.new!(activity_2.working_day_start.year, 1, 1)}",
          date_end: "#{Date.new!(activity_2.working_day_start.year, 12, 31)}"
        }
      )
    end
  end
end
