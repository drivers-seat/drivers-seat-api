defmodule DriversSeatCoopWeb.HourlyEarningView do
  use DriversSeatCoopWeb, :view
  alias DriversSeatCoopWeb.HourlyEarningView

  def render("index.json", %{hourly_earnings: hourly_earnings}) do
    %{data: render_many(hourly_earnings, HourlyEarningView, "hourly_earning.json")}
  end

  def render("hourly_earning.json", %{hourly_earning: hourly_earning}) do
    %{
      date: hourly_earning.date,
      gross_pay: Decimal.round(hourly_earning.cents_average_hourly_gross) |> Decimal.to_integer(),
      net_pay: Decimal.round(hourly_earning.cents_average_hourly_net) |> Decimal.to_integer(),
      user_id: hourly_earning.user_id
    }
  end
end
