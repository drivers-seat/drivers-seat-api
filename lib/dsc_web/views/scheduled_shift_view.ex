defmodule DriversSeatCoopWeb.ScheduledShiftView do
  use DriversSeatCoopWeb, :view
  alias DriversSeatCoopWeb.ScheduledShiftView

  def render("index.json", %{scheduled_shifts: scheduled_shifts}) do
    %{data: render_many(scheduled_shifts, ScheduledShiftView, "scheduled_shift.json")}
  end

  def render("scheduled_shift.json", %{scheduled_shift: scheduled_shift}) do
    %{
      user_id: scheduled_shift.user_id,
      start_day_of_week: scheduled_shift.start_day_of_week,
      start_time_local: scheduled_shift.start_time_local,
      duration_minutes: scheduled_shift.duration_minutes
    }
  end
end
