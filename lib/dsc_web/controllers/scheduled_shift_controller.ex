defmodule DriversSeatCoopWeb.ScheduledShiftController do
  use DriversSeatCoopWeb, :controller
  alias DriversSeatCoop.ScheduledShifts

  plug DriversSeatCoopWeb.AuthenticationPlug
  action_fallback DriversSeatCoopWeb.FallbackController

  def index(conn, _params) do
    scheduled_shifts = ScheduledShifts.list_scheduled_shifts_by_user_id(conn.assigns.user.id)
    render(conn, "index.json", scheduled_shifts: scheduled_shifts)
  end

  def create(conn, %{"scheduled_shifts" => scheduled_shift_params}) do
    scheduled_shift_params = List.wrap(scheduled_shift_params)

    with {:ok, scheduled_shifts} <-
           ScheduledShifts.update_scheduled_shifts(scheduled_shift_params, conn.assigns.user.id) do
      render(conn, "index.json", scheduled_shifts: scheduled_shifts)
    end
  end
end
