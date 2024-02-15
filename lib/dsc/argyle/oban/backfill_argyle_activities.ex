defmodule DriversSeatCoop.Argyle.Oban.BackfillArgyleActivities do
  @moduledoc """
  This job will grab all historical argyle activities for a user and insert them
  into the DB.

  New users should have this job triggered for them automatically when an argyle
  account is linked. Old users can also have this job manually triggered to
  attempt to fill in missing activities.

  This is the only way to backfill the deleted column in the activities table
  when the webhook for handling deleted activities fails.
  """

  use Oban.Worker,
    queue: :argyle_api,
    max_attempts: 5,
    unique: [period: 600]

  require Logger
  alias DriversSeatCoop.{Accounts, Argyle, Driving}
  alias DriversSeatCoop.Earnings.Oban.UpdateTimeSpansForUser

  def schedule_job(user_id) do
    new(%{user_id: user_id})
    |> Oban.insert()
  end

  @impl Oban.Worker
  def perform(%Oban.Job{id: id, args: %{"user_id" => user_id}}) do
    Logger.metadata(oban_job_id: id)

    Logger.info("Backfilling argyle activities for #{user_id}")

    user = Accounts.get_user!(user_id)

    if user.is_demo_account do
      Logger.info("Ignoring request to backfill argyle activities for demo account #{user_id}")
    else
      fetched_activity_ids =
        Argyle.backfill_argyle_activities(user)
        |> MapSet.new()

      existing_activity_ids =
        Driving.list_activity_ids_by_user_id(user.id)
        |> MapSet.new()

      # this only works because we have fetched all argyle activities for the user
      deleted_activities =
        MapSet.difference(existing_activity_ids, fetched_activity_ids)
        |> MapSet.to_list()

      Driving.delete_activities(deleted_activities)
    end

    UpdateTimeSpansForUser.schedule_job(user.id)

    :ok
  end

  @impl Oban.Worker
  def timeout(_job), do: :timer.minutes(30)
end
