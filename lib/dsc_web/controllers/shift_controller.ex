defmodule DriversSeatCoopWeb.ShiftController do
  use DriversSeatCoopWeb, :controller
  alias DriversSeatCoop.Earnings
  alias DriversSeatCoop.Earnings.Oban.UpdateTimeSpansForUserWorkday
  alias DriversSeatCoop.Goals.Oban.CalculatePerformanceForUserWindow
  alias DriversSeatCoop.Shifts
  alias DriversSeatCoop.Shifts.Shift

  plug DriversSeatCoopWeb.AuthenticationPlug
  action_fallback DriversSeatCoopWeb.FallbackController

  def index(conn, params) do
    with {:ok, params} <- DriversSeatCoopWeb.ShiftValidator.index(params) do
      shifts = Shifts.list_shifts_by_user_id(conn.assigns.user, params)
      render(conn, "index.json", shifts: shifts)
    end
  end

  def create(conn, %{"shift" => shift_params}) do
    device = Map.get(conn.assigns, :dsc_device)

    device_id =
      if is_nil(device) do
        nil
      else
        device.id
      end

    with {:ok, %Shift{} = shift} <-
           Shifts.create_shift(shift_params, conn.assigns.user.id, device_id) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.shift_path(conn, :show, shift))
      |> render("show.json", shift: shift)
    end
  end

  def show(conn, %{"id" => id}) do
    shift = Shifts.get_shift!(id)

    with :ok <- DriversSeatCoop.Authorizer.authorize(:show, shift, conn.assigns.user) do
      render(conn, "show.json", shift: shift)
    end
  end

  def update(conn, %{"id" => id, "shift" => shift_params}) do
    shift = Shifts.get_shift!(id)

    with :ok <- DriversSeatCoop.Authorizer.authorize(:update, shift, conn.assigns.user),
         {:ok, %Shift{} = updated_shift} <- Shifts.update_shift(shift, shift_params) do
      if not is_nil(updated_shift.start_time) and not is_nil(updated_shift.end_time) do
        UpdateTimeSpansForUserWorkday.schedule_jobs_for_date_range(
          updated_shift.user_id,
          updated_shift.start_time,
          updated_shift.end_time,
          120
        )

        CalculatePerformanceForUserWindow.schedule_jobs_for_date_range(
          updated_shift.user_id,
          updated_shift.start_time,
          updated_shift.end_time
        )
      end

      render(conn, "show.json", shift: updated_shift)
    end
  end

  def update_working_time(conn, params) do
    with {:ok, params} <- DriversSeatCoopWeb.ShiftValidator.update_working_times(params) do
      work_day = Map.get(params, :work_date)
      new_shifts = Map.get(params, :new_shifts)

      with {:ok, _} <- Shifts.update_working_times(conn.assigns.user, work_day, new_shifts) do
        # update timespans and allocations so that the user sees their changes reflected
        Earnings.update_timespans_and_allocations_for_user_workday(conn.assigns.user, work_day)

        Earnings.update_timespans_and_allocations_for_user_workday(
          conn.assigns.user,
          Date.add(work_day, 1)
        )

        Earnings.update_timespans_and_allocations_for_user_workday(
          conn.assigns.user,
          Date.add(work_day, -1)
        )

        send_resp(conn, :no_content, "")
      end
    end
  end
end
