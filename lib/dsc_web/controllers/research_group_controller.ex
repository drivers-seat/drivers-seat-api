defmodule DriversSeatCoopWeb.ResearchGroupController do
  use DriversSeatCoopWeb, :controller

  alias DriversSeatCoop.Research
  alias DriversSeatCoop.Research.ResearchGroup

  action_fallback DriversSeatCoopWeb.FallbackController

  def lookup(conn, %{"code" => code}) do
    case Research.get_research_group_by_case_insensitive_code(code) do
      %ResearchGroup{} = rg ->
        render(conn, "show.json", research_group: rg)

      _ ->
        conn
        |> put_status(:not_found)
        |> put_view(DriversSeatCoopWeb.ErrorView)
        |> render(:"404")
    end
  end
end
