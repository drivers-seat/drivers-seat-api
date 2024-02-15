defmodule DriversSeatCoopWeb.Admin.ObanJobControllerTest do
  alias DriversSeatCoop.ObanTestJob
  use DriversSeatCoopWeb.ConnCase
  use Oban.Testing, repo: DriversSeatCoop.Repo

  defp admin_session(state) do
    admin = Factory.create_admin_user()
    conn = TestHelpers.put_admin_session(state.conn, admin)

    {:ok, conn: conn, admin: admin}
  end

  def fixture(:job) do
    {:ok, job} = ObanTestJob.schedule_job()

    job
  end

  describe "index" do
    setup [:admin_session, :create_job]

    test "lists all oban_jobs", %{conn: conn} do
      conn = get(conn, Routes.admin_oban_job_path(conn, :index))
      assert html_response(conn, 200) =~ "Oban jobs"
    end
  end

  describe "show job" do
    setup [:admin_session, :create_job]

    test "shows given job", %{conn: conn, job: job} do
      conn = get(conn, Routes.admin_oban_job_path(conn, :show, job))
      assert html_response(conn, 200) =~ "Job Details"
    end
  end

  describe "delete job" do
    setup [:admin_session, :create_job]

    test "deletes chosen job", %{conn: conn, job: job} do
      conn = delete(conn, Routes.admin_oban_job_path(conn, :delete, job))
      assert redirected_to(conn) == Routes.admin_oban_job_path(conn, :index)

      assert_error_sent 404, fn ->
        get(conn, Routes.admin_oban_job_path(conn, :show, job))
      end

      # nothing should be queued up
      refute_enqueued(worker: DriversSeatCoop.ObanTestJob)
    end
  end

  describe "cancel job" do
    setup [:admin_session, :create_job]

    test "cancels chosen job", %{conn: conn, job: job} do
      conn = post(conn, Routes.admin_oban_job_path(conn, :cancel, job))
      assert redirected_to(conn) == Routes.admin_oban_job_path(conn, :index)

      # job still exists
      conn = get(conn, Routes.admin_oban_job_path(conn, :show, job))
      assert html_response(conn, 200) =~ "Job Details"

      # job is marked as cancelled
      job = DriversSeatCoop.Oban.get_job!(job.id)
      assert job.state == "cancelled"
    end
  end

  describe "retry job" do
    setup [:admin_session, :create_job]

    test "retries chosen job", %{conn: conn, job: job} do
      Oban.drain_queue(queue: :argyle_api)

      # job is marked as completed
      job = DriversSeatCoop.Oban.get_job!(job.id)
      assert job.state == "completed"

      conn = post(conn, Routes.admin_oban_job_path(conn, :retry, job))
      assert redirected_to(conn) == Routes.admin_oban_job_path(conn, :index)

      # job still exists
      conn = get(conn, Routes.admin_oban_job_path(conn, :show, job))
      assert html_response(conn, 200) =~ "Job Details"

      # job is marked as available again
      job = DriversSeatCoop.Oban.get_job!(job.id)
      assert job.state == "available"
    end
  end

  defp create_job(_) do
    job = fixture(:job)
    {:ok, job: job}
  end
end
