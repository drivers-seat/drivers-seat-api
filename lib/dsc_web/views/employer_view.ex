defmodule DriversSeatCoopWeb.EmployerView do
  use DriversSeatCoopWeb, :view
  alias DriversSeatCoopWeb.EmployerView

  def render("index.json", %{employers: employers}) do
    %{data: render_many(employers, EmployerView, "employer.json")}
  end

  def render("employer.json", %{employer: employer}) do
    %{
      id: employer.id,
      name: employer.employer.name,
      service_class_id: employer.service_class_id,
      service_class: employer.service_class.name,
      reports_mileage: employer.reports_mileage,
      reports_p2_duration: nil,
      reports_shifts: nil,
      reports_origin: nil,
      reports_destination: nil
    }
  end
end
