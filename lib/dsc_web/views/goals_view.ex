defmodule DriversSeatCoopWeb.GoalsView do
  use DriversSeatCoopWeb, :view

  def render("index.json", %{goals: goals}) do
    %{
      data: render_goals(goals)
    }
  end

  def render("performance.json", %{performance: performance}) do
    %{
      data: Enum.map(performance, fn {meas, goal} -> render_goal_performance(meas, goal) end)
    }
  end

  defp render_goals(goals) do
    goals
    |> Enum.group_by(
      fn g -> Map.take(g, [:type, :frequency, :start_date]) end,
      fn g -> Map.put(%{}, g.sub_frequency, g.amount) end
    )
    |> Enum.to_list()
    |> Enum.map(fn {goal, vals} ->
      sub_goals = Enum.reduce(vals, %{}, fn val, model -> Map.merge(val, model) end)
      Map.put(goal, :sub_goals, sub_goals)
    end)
  end

  defp render_goal_performance(measurement, goal) do
    %{
      type: goal.type,
      frequency: goal.frequency,
      sub_frequency: goal.sub_frequency,
      window_date: measurement.window_date,
      goal_amount: goal.amount,
      performance_amount: measurement.performance_amount,
      performance_percent: measurement.performance_percent,
      additional_info: measurement.additional_info
    }
  end
end
