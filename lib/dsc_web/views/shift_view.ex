defmodule DriversSeatCoopWeb.ShiftView do
  use DriversSeatCoopWeb, :view
  alias DriversSeatCoopWeb.ShiftView

  def render("index.json", %{shifts: shifts}) do
    %{data: render_many(shifts, ShiftView, "shift.json")}
  end

  def render("show.json", %{shift: shift}) do
    %{data: render_one(shift, ShiftView, "shift.json")}
  end

  def render("shift.json", %{shift: shift}) do
    %{
      id: shift.id,
      end_time: shift.end_time,
      frontend_mileage: shift.frontend_mileage,
      start_time: shift.start_time,
      user_id: shift.user_id
    }
  end
end
