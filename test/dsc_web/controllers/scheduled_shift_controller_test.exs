defmodule DriversSeatCoopWeb.ScheduledShiftControllerTest do
  use DriversSeatCoopWeb.ConnCase, async: true

  @shift_1 %{
    start_day_of_week: 6,
    start_time_local: ~T[16:00:00],
    duration_minutes: 720
  }

  @shift_2 %{
    start_day_of_week: 0,
    start_time_local: ~T[16:00:00],
    duration_minutes: 360
  }

  @shift_3 %{
    start_day_of_week: 1,
    start_time_local: ~T[00:00:00],
    duration_minutes: 120
  }

  @invalid_shift %{
    start_day_of_week: 6,
    start_time_of_day: ~T[23:59:00],
    duration_minutes: -10
  }

  setup %{conn: conn} do
    user = Factory.create_user()

    conn =
      put_req_header(conn, "accept", "application/json")
      |> TestHelpers.put_auth_header(user)

    {:ok, conn: conn, user: user}
  end

  describe "index" do
    test "lists all scheduled shifts", %{conn: conn, user: user} do
      keys = Map.keys(@shift_1)

      expected =
        Factory.create_scheduled_shifts(user.id, [@shift_1, @shift_2])
        |> Enum.map(fn s ->
          Map.take(s, keys)
        end)

      conn = get(conn, Routes.scheduled_shift_path(conn, :index))

      actual =
        json_response(conn, 200)["data"]
        |> extract_scheduled_shifts_from_response()

      assert expected == actual
    end

    test "returns empty when no scheduled shifts for user", %{conn: conn, user: user} do
      _expected = Factory.create_scheduled_shifts(user.id, [])

      conn = get(conn, Routes.scheduled_shift_path(conn, :index))

      assert [] == json_response(conn, 200)["data"]
    end
  end

  describe "create" do
    test "saves scheduled shifts when data is valid", %{conn: conn, user: _user} do
      conn = get(conn, Routes.scheduled_shift_path(conn, :index))
      actual_before = json_response(conn, 200)["data"]

      expected_after =
        [@shift_1, @shift_2]
        |> Enum.sort_by(&{&1.start_day_of_week, &1.start_time_local})

      conn =
        post(conn, Routes.scheduled_shift_path(conn, :create), scheduled_shifts: expected_after)

      actual_after =
        json_response(conn, 200)["data"]
        |> extract_scheduled_shifts_from_response()
        |> Enum.sort_by(&{&1.start_day_of_week, &1.start_time_local})

      assert actual_before == []
      assert actual_after == expected_after
    end

    test "replaces scheduled shifts when data is valid", %{conn: conn, user: user} do
      Factory.create_scheduled_shifts(user.id, [@shift_1, @shift_2])

      expected_after =
        [@shift_2, @shift_3]
        |> Enum.sort_by(&{&1.start_day_of_week, &1.start_time_local})

      conn =
        post(conn, Routes.scheduled_shift_path(conn, :create), scheduled_shifts: expected_after)

      actual_after =
        json_response(conn, 200)["data"]
        |> extract_scheduled_shifts_from_response()
        |> Enum.sort_by(&{&1.start_day_of_week, &1.start_time_local})

      assert actual_after == expected_after
    end

    test "replaces scheduled shifts when data is empty", %{conn: conn, user: user} do
      Factory.create_scheduled_shifts(user.id, [@shift_1, @shift_2])

      conn = post(conn, Routes.scheduled_shift_path(conn, :create), scheduled_shifts: [])

      actual_after =
        json_response(conn, 200)["data"]
        |> extract_scheduled_shifts_from_response()

      assert actual_after == []
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn =
        post(conn, Routes.scheduled_shift_path(conn, :create), scheduled_shifts: [@invalid_shift])

      assert json_response(conn, 422)
    end
  end

  defp extract_scheduled_shifts_from_response(data) do
    Enum.map(data, fn s ->
      {:ok, start_time_local} = Time.from_iso8601(Map.get(s, "start_time_local"))

      %{
        start_day_of_week: Map.get(s, "start_day_of_week"),
        start_time_local: start_time_local,
        duration_minutes: Map.get(s, "duration_minutes")
      }
    end)
  end
end
