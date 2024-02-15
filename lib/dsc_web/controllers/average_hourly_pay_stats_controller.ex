defmodule DriversSeatCoopWeb.AverageHourlyPayStatsController do
  use DriversSeatCoopWeb, :controller
  alias DriversSeatCoop.CommunityInsights
  alias DriversSeatCoopWeb.AverageHourlyPayStatsValidator

  def summary(conn, %{
        "options" => params
      }) do
    with {:ok, params} <- AverageHourlyPayStatsValidator.summary(params) do
      stats =
        CommunityInsights.get_summary(
          params.metro_area_id,
          Map.get(params, :employer_ids),
          Map.get(params, :service_class_ids)
        )

      render(conn, "summary.json", stats: stats)
    end
  end

  def trend(conn, %{
        "options" => params
      }) do
    with {:ok, params} <- AverageHourlyPayStatsValidator.trend(params) do
      params = Map.put(params, :hour_local, Time.new!(params.hour_of_day, 0, 0))

      stats =
        CommunityInsights.get_trend(
          params.metro_area_id,
          params.day_of_week,
          params.hour_local,
          Map.get(params, :employer_ids),
          Map.get(params, :service_class_ids)
        )

      render(conn, "trend.json", stats: stats)
    end
  end
end
