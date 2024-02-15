defmodule DriversSeatCoop.Notifications.Oban.CTACommunityInsights do
  @moduledoc """
  This job will send an engagement push notification to users 72-hours after signing up.
  """

  import Ecto.Query, warn: false

  use Oban.Worker,
    queue: :notifications,
    unique: [
      period: :infinity,
      states: [:available, :scheduled, :executing, :completed],
      keys: [:user_id]
    ],
    max_attempts: 3

  require Logger

  alias DriversSeatCoop.Accounts
  alias DriversSeatCoop.Accounts.User
  alias DriversSeatCoop.AppPreferences
  alias DriversSeatCoop.OneSignal
  alias DriversSeatCoop.Regions
  alias DriversSeatCoop.Repo

  @cutoff_date ~N[2023-04-06 07:00:00.000000]
  @schedule_future_minutes 60 * 24 * 3
  @hourly_pay_stat_coverage_percent_min Decimal.from_float(0.25)

  def schedule_job(%User{} = user) do
    cond do
      NaiveDateTime.compare(user.inserted_at, @cutoff_date) == :lt ->
        {:ok, :not_scheduled_user_existed_before_CTA}

      not User.has_profile?(user) ->
        {:ok, :not_scheduled_profile_incomplete}

      true ->
        scheduled_at_utc =
          DateTime.utc_now()
          |> DateTime.add(@schedule_future_minutes, :minute)

        new(%{user_id: user.id},
          scheduled_at: scheduled_at_utc,
          replace: []
        )
        |> Oban.insert()
    end
  end

  @impl Oban.Worker
  def perform(%Oban.Job{
        id: id,
        args: %{
          "user_id" => user_id
        }
      }) do
    Logger.metadata(oban_job_id: id)

    Logger.info("Processing CTA - Welcome to Community Insights for #{user_id}")

    user = Accounts.get_user!(user_id)

    cond do
      # user is deleted
      user.deleted ->
        {:ok, :not_sent_user_deleted}

      # not able to receive notifications (opted out)
      not User.can_receive_notification(user) ->
        {:ok, :not_sent_notifications_not_enabled_for_user}

      true ->
        send_notification(user)
    end
  end

  defp send_notification(%User{} = user) do
    pref_value = AppPreferences.get_user_app_preference(user.id, "average_hourly_pay_analytics")

    metro_area =
      if is_nil(pref_value),
        do: nil,
        else: Regions.get_metro_area_by_id(Map.get(pref_value.value, "metro_area_id"))

    metro_area = metro_area || Regions.get_metro_area_by_id(user.metro_area_id)

    send_notification(user, metro_area)
  end

  defp send_notification(%User{} = user, nil = _metro_area) do
    qry =
      Regions.query_metro_areas()
      |> Regions.query_metro_areas_hourly_pay_stat_coverage_percent(
        @hourly_pay_stat_coverage_percent_min,
        nil
      )

    count_workers =
      from(metro in qry,
        select: sum(metro.count_workers),
        limit: 1
      )
      |> Repo.one()

    OneSignal.send_cta_welcome_to_community_insights_no_metro(user, count_workers)
  end

  defp send_notification(%User{} = user, metro_area) do
    metro_does_not_have_insights =
      is_nil(metro_area.hourly_pay_stat_coverage_percent) or
        Decimal.lt?(
          metro_area.hourly_pay_stat_coverage_percent,
          @hourly_pay_stat_coverage_percent_min
        )

    user_has_earnings = Accounts.user_has_earnings?(user.id)

    OneSignal.send_cta_welcome_to_community_insights_has_metro(
      user,
      metro_area,
      not metro_does_not_have_insights,
      user_has_earnings
    )
  end

  @impl Oban.Worker
  def timeout(_job), do: :timer.minutes(2)
end
