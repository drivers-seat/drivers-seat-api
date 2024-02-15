defmodule DriversSeatCoopWeb.GoalsController do
  use DriversSeatCoopWeb, :controller

  alias DriversSeatCoop.Goals

  def index(conn, params) do
    with {:ok, params} <- DriversSeatCoopWeb.GoalsValidator.index(params) do
      frequency = Map.get(params, :frequency)

      render_available_goals(conn, frequency)
    end
  end

  def save(conn, params) do
    with {:ok, params} <- DriversSeatCoopWeb.GoalsValidator.save(params) do
      type = Map.get(params, :type)
      frequency = Map.get(params, :frequency)
      start_date = Map.get(params, :start_date)
      sub_goals = Map.get(params, :sub_goals)
      replace_date = Map.get(params, :replace)

      with {:ok, _} <-
             Goals.update_goals(
               conn.assigns.user.id,
               type,
               frequency,
               start_date,
               sub_goals,
               replace_date
             ) do
        render_available_goals(conn, frequency)
      end
    end
  end

  def delete(conn, params) do
    with {:ok, params} <- DriversSeatCoopWeb.GoalsValidator.delete(params) do
      type = Map.get(params, :type)
      frequency = Map.get(params, :frequency)
      start_date = Map.get(params, :start_date)

      with {:ok, _} <- Goals.delete_goals(conn.assigns.user.id, type, frequency, start_date) do
        render_available_goals(conn, frequency)
      end
    end
  end

  def performance(conn, params) do
    with {:ok, params} <- DriversSeatCoopWeb.GoalsValidator.performance(params) do
      frequency = Map.get(params, :frequency)
      window_date = Map.get(params, :window_date)

      performance = Goals.get_goal_performance(conn.assigns.user.id, frequency, window_date)

      render(conn, "performance.json", performance: performance)
    end
  end

  defp render_available_goals(conn, frequency) do
    goals = Goals.get_goals(conn.assigns.user.id, frequency)
    render(conn, "index.json", goals: goals)
  end
end
