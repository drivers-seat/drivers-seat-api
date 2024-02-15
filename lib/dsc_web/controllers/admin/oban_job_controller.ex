defmodule DriversSeatCoopWeb.Admin.ObanJobController do
  use DriversSeatCoopWeb, :controller

  plug(:put_root_layout, {DriversSeatCoopWeb.LayoutView, "torch.html"})
  plug(:put_layout, false)

  def index(conn, params) do
    case DriversSeatCoop.Oban.paginate_oban_jobs(params) do
      {:ok, assigns} ->
        render(conn, "index.html", assigns)

      error ->
        conn
        |> put_flash(:error, "There was an error rendering Oban jobs. #{inspect(error)}")
        |> redirect(to: Routes.admin_oban_job_path(conn, :index))
    end
  end

  def show(conn, %{"id" => id}) do
    job = DriversSeatCoop.Oban.get_job!(id)
    render(conn, "show.html", job: job)
  end

  def retry(conn, %{"id" => id}) do
    {id, ""} = Integer.parse(id)
    :ok = Oban.retry_job(id)

    conn
    |> put_flash(:info, "Job successfully marked to be retried.")
    |> redirect(to: Routes.admin_oban_job_path(conn, :index))
  end

  def cancel(conn, %{"id" => id}) do
    {id, ""} = Integer.parse(id)
    :ok = Oban.cancel_job(id)

    conn
    |> put_flash(:info, "Job cancelled successfully.")
    |> redirect(to: Routes.admin_oban_job_path(conn, :index))
  end

  def delete(conn, %{"id" => id}) do
    job = DriversSeatCoop.Oban.get_job!(id)
    {:ok, _job} = DriversSeatCoop.Oban.delete_job(job)

    conn
    |> put_flash(:info, "Job deleted successfully.")
    |> redirect(to: Routes.admin_oban_job_path(conn, :index))
  end
end
