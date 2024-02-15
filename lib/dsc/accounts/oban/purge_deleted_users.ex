defmodule DriversSeatCoop.Accounts.Oban.PurgeDeletedUsers do
  @moduledoc """
  This job is responsible for purging deleted users from external services
  and the DSC database
  """

  use Oban.Worker,
    queue: :purge,
    unique: [
      period: :infinity,
      states: [:available, :scheduled, :executing],
      keys: [:user_id]
    ],
    max_attempts: 3

  require Logger
  import Ecto.Query, warn: false
  alias DriversSeatCoop.Accounts
  alias DriversSeatCoop.ExternalServices
  alias DriversSeatCoop.Repo

  def schedule_jobs do
    Accounts.get_users_query(true)
    |> Accounts.filter_for_deleted(true)
    |> select([u], u.id)
    |> Repo.all()
    |> schedule_job()
  end

  def schedule_job(user_id_or_ids) do
    List.wrap(user_id_or_ids)
    |> Enum.each(fn user_id -> Oban.insert(new(%{user_id: user_id})) end)

    :ok
  end

  @impl Oban.Worker
  def perform(%Oban.Job{
        id: id,
        args: %{
          "user_id" => user_id
        }
      }) do
    Logger.metadata(oban_job_id: id)
    Logger.info("Purging User #{user_id}")
    user = Accounts.get_user!(user_id)

    # use user_id here so that we re-fetch the user record from the
    # db.  This ensures that we have the most up to date delete flag
    if user.deleted do
      with {:ok, _} <- ExternalServices.delete_user(user_id) do
        Accounts.purge_user!(user_id)
      end
    else
      {:error, :user_not_marked_for_deletion}
    end
  end

  @impl Oban.Worker
  def perform(%Oban.Job{
        id: id
      }) do
    Logger.metadata(oban_job_id: id)
    Logger.info("Scheduling jobs for users to be purged")
    schedule_jobs()
    :ok
  end

  @impl Oban.Worker
  def timeout(_job), do: :timer.minutes(45)
end
