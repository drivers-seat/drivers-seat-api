defmodule DriversSeatCoopWeb.ArgyleWebhookController do
  use DriversSeatCoopWeb, :controller
  require Logger

  alias DriversSeatCoop.{Accounts, Driving}
  alias DriversSeatCoop.Argyle.Oban.{GetNewActivities, ImportArgyleProfileInformation}
  alias DriversSeatCoop.Earnings.Oban.UpdateTimeSpansForUserWorkday
  alias DriversSeatCoop.Goals.Oban.CalculatePerformanceForUserWindow

  def create(conn, %{"event" => event, "data" => data})
      when event in ["activities.removed", "gigs.removed"] do
    # Triggered when a group of activities are removed from a user's account.
    %{
      "account" => _account_id,
      "removed_from" => beginning,
      "removed_to" => ending,
      "user" => argyle_user_id
    } = data

    removed_activities = Map.get(data, "removed_activities", Map.get(data, "removed_gigs"))

    Logger.info(
      "Executing Argyle Webhook #{event}: beginning: #{beginning} ending: #{ending} argyle_user_id: #{argyle_user_id}"
    )

    case Accounts.get_user_by_argyle_user_id(argyle_user_id) do
      nil ->
        send_missing_argyle_id_response(conn, argyle_user_id, data)

      user ->
        Driving.delete_activities(removed_activities)

        # trigger job to rebuild work time data, which will remove the deleted activities
        # in the process
        UpdateTimeSpansForUserWorkday.schedule_jobs_for_date_range(
          user.id,
          beginning,
          ending,
          nil
        )

        CalculatePerformanceForUserWindow.schedule_jobs_for_date_range(
          user.id,
          beginning,
          ending
        )

        conn
        |> send_resp(:no_content, "")
    end
  end

  def create(conn, %{"event" => event, "data" => data})
      when event in ["activities.added", "gigs.added"] do
    # Triggered when a group of activities are added to a user's account.
    %{
      "account" => account_id,
      "added_from" => beginning,
      "added_to" => ending,
      "user" => argyle_user_id
    } = data

    Logger.info(
      "Executing Argyle Webhook #{event}: beginning: #{beginning} ending: #{ending} argyle_user_id: #{argyle_user_id}, account_id: #{account_id}"
    )

    conn
    |> handle_activities_change(account_id, argyle_user_id, beginning, ending, data)
  end

  def create(conn, %{"event" => event, "data" => data})
      when event in ["activities.updated", "gigs.updated"] do
    # Triggered when a group of activities are updated in a user's account.
    %{
      "account" => account_id,
      "updated_from" => beginning,
      "updated_to" => ending,
      "user" => argyle_user_id
    } = data

    Logger.info(
      "Executing Argyle Webhook #{event}: beginning: #{beginning} ending: #{ending} argyle_user_id: #{argyle_user_id}, account_id: #{account_id}"
    )

    conn
    |> handle_activities_change(account_id, argyle_user_id, beginning, ending, data)
  end

  def create(conn, %{"event" => event, "data" => data})
      when event in ["activities.fully_synced", "gigs.fully_synced"] do
    # Triggered when activities from the initial pull are available.
    %{
      "account" => account_id,
      "available_from" => beginning,
      "available_to" => ending,
      "user" => argyle_user_id
    } = data

    Logger.info(
      "Executing Argyle Webhook #{event}: beginning: #{beginning} ending: #{ending} argyle_user_id: #{argyle_user_id}, account_id: #{account_id}"
    )

    if is_nil(beginning) or is_nil(ending) do
      # sometimes these params are null when activity_count is zero. ignore
      # those events
      conn
      |> send_resp(:no_content, "")
    else
      conn
      |> handle_activities_change(account_id, argyle_user_id, beginning, ending, data)
    end
  end

  def create(conn, %{"event" => event, "data" => data})
      when event in [
             "profiles.added",
             "profiles.updated",
             "identities.added",
             "identities.updated",
             "vehicles.added",
             "vehicles.updated"
           ] do
    %{"user" => argyle_user_id} = data

    Logger.info("Executing Argyle Webhook #{event}: argyle_user_id: #{argyle_user_id}")

    conn |> handle_profile_change(argyle_user_id, data)
  end

  defp handle_profile_change(conn, argyle_user_id, data) do
    case Accounts.get_user_by_argyle_user_id(argyle_user_id) do
      nil ->
        send_missing_argyle_id_response(conn, argyle_user_id, data)

      user ->
        ImportArgyleProfileInformation.schedule_job(user.id)

        conn
        |> send_resp(:no_content, "")
    end
  end

  defp handle_activities_change(conn, account_id, argyle_user_id, beginning, ending, data) do
    case Accounts.get_user_by_argyle_user_id(argyle_user_id) do
      nil ->
        send_missing_argyle_id_response(conn, argyle_user_id, data)

      user ->
        # trigger backfill job, but limit it to a given account and date. this
        # should not get discarded by the uniqueness checker
        GetNewActivities.schedule_job(user.id, account_id, beginning, ending)

        conn
        |> send_resp(:no_content, "")
    end
  end

  defp send_missing_argyle_id_response(conn, argyle_user_id, data) do
    Logger.warn("User not found with argyle id #{argyle_user_id}")

    Sentry.capture_message("User not found with argyle id",
      extra: %{webhook_data: data}
    )

    conn
    |> send_resp(:unprocessable_entity, "user not found")
  end
end
