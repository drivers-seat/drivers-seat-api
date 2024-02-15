defmodule DriversSeatCoop.Expenses.Oban.ExportUserExpensesQuery do
  @moduledoc """
  This job will be responsible for fulfilling a user's request for
  download of their earnings data
  """

  use Oban.Worker,
    queue: :user_export_request,
    max_attempts: 3

  @expiration_seconds 172_800

  require Logger
  alias DriversSeatCoop.Accounts
  alias DriversSeatCoop.B2
  alias DriversSeatCoop.Export.Oban.DeleteExpiredExportFile
  alias DriversSeatCoop.Export.UserRequest.Expenses

  def schedule_job(
        user_id,
        params
      ) do
    new(Map.put(params, :user_id, user_id))
    |> Oban.insert()
  end

  @impl Oban.Worker
  def perform(%Oban.Job{
        id: id,
        args:
          %{
            "user_id" => user_id,
            "date_start" => date_start,
            "date_end" => date_end
          } = args
      }) do
    Logger.metadata(oban_job_id: id)

    Logger.info("Processing user expenses query export request for #{user_id}")

    user = Accounts.get_user!(user_id)
    {:ok, file_info} = Expenses.export_expenses_for_user_query(user_id, args)

    # schedule file to be deleted after expiration.
    DeleteExpiredExportFile.schedule_job(
      file_info.file_id,
      file_info.file_name,
      @expiration_seconds
    )

    download_url = B2.get_presigned_download_url(file_info.file_name, @expiration_seconds)

    email =
      DriversSeatCoopWeb.DownloadExpensesEmail.download_expenses(
        user,
        download_url,
        date_start,
        date_end
      )

    with {:ok, _} <- DriversSeatCoopWeb.Mailer.deliver(email) do
      :ok
    end
  end

  @impl Oban.Worker
  def timeout(_job), do: :timer.minutes(2)
end
