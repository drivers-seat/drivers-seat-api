defmodule DriversSeatCoopWeb.Admin.ResearchGroupController do
  use DriversSeatCoopWeb, :controller

  alias DriversSeatCoop.Research
  alias DriversSeatCoop.Research.ResearchGroup

  plug(:put_layout, {DriversSeatCoopWeb.LayoutView, "torch.html"})

  def index(conn, _params) do
    research_groups = Research.list_research_groups()
    render(conn, "index.html", research_groups: research_groups)
  end

  def new(conn, _params) do
    changeset = Research.change_research_group(%ResearchGroup{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"research_group" => research_group_params}) do
    case Research.create_research_group(research_group_params) do
      {:ok, research_group} ->
        conn
        |> put_flash(:info, "Research group created successfully.")
        |> redirect(to: Routes.admin_research_group_path(conn, :show, research_group))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    research_group = Research.get_research_group!(id)
    render(conn, "show.html", research_group: research_group)
  end

  def edit(conn, %{"id" => id}) do
    research_group = Research.get_research_group!(id)
    changeset = Research.change_research_group(research_group)
    render(conn, "edit.html", research_group: research_group, changeset: changeset)
  end

  def update(conn, %{"id" => id, "research_group" => research_group_params}) do
    research_group = Research.get_research_group!(id)

    case Research.update_research_group(research_group, research_group_params) do
      {:ok, research_group} ->
        conn
        |> put_flash(:info, "Research group updated successfully.")
        |> redirect(to: Routes.admin_research_group_path(conn, :show, research_group))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", research_group: research_group, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    research_group = Research.get_research_group!(id)
    {:ok, _research_group} = Research.delete_research_group(research_group)

    conn
    |> put_flash(:info, "Research group deleted successfully.")
    |> redirect(to: Routes.admin_research_group_path(conn, :index))
  end
end
