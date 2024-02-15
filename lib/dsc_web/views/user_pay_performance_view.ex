defmodule DriversSeatCoopWeb.UserPayPerformanceView do
  use DriversSeatCoopWeb, :view
  alias DriversSeatCoopWeb.UserPayPerformanceView

  def render("show.json", %{pay_performance: metrics}) do
    %{data: render_one(metrics, UserPayPerformanceView, "pay_performance.json")}
  end

  def render("pay_performance.json", %{user_pay_performance: metrics}) do
    %{
      by_employer:
        Enum.map(metrics.by_employer, fn emp_metric ->
          %{
            employer: emp_metric.employer,
            cents_expenses_mileage: to_integer(emp_metric.cents_irs_mileage_expense_total),
            cents_pay: to_integer(emp_metric.cents_pay),
            cents_promotion: to_integer(emp_metric.cents_promotion),
            cents_tip: to_integer(emp_metric.cents_tip),
            miles_total: round_number(emp_metric.miles_total),
            seconds_p3: to_integer(emp_metric.seconds_p3),
            seconds_total: to_integer(emp_metric.seconds_total),
            tasks_total: to_integer(emp_metric.tasks_total)
          }
        end),
      cents_average_hourly_gross: to_integer(metrics.cents_average_hourly_gross),
      cents_average_hourly_net: to_integer(metrics.cents_average_hourly_net),
      cents_earnings_gross: to_integer(metrics.cents_earnings_gross),
      cents_earnings_net: to_integer(metrics.cents_earnings_net),
      cents_expenses_deductible: to_integer(metrics.cents_expenses_deductible),
      cents_expenses_mileage: to_integer(metrics.cents_irs_mileage_expense_total),
      cents_pay: to_integer(metrics.cents_pay),
      cents_promotion: to_integer(metrics.cents_promotion),
      cents_tip: to_integer(metrics.cents_tip),
      miles_total: round_number(metrics.miles_total),
      seconds_p3: to_integer(metrics.seconds_p3),
      seconds_total: to_integer(metrics.seconds_total),
      tasks_total: to_integer(metrics.tasks_total)
    }
  end

  defp to_integer(nil), do: 0

  defp to_integer(number), do: Decimal.round(number) |> Decimal.to_integer()

  defp round_number(nil), do: 0

  defp round_number(number), do: Decimal.round(number, 2) |> Decimal.to_float()
end
