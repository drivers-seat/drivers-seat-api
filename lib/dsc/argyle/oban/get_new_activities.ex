defmodule DriversSeatCoop.Argyle.Oban.GetNewActivities do
  @moduledoc """
  This job will attempt to grab new argyle activities for each user with a
  linked argyle account.
  """

  use Oban.Worker,
    queue: :argyle_api,
    max_attempts: 1,
    unique: [period: 600]

  require Logger
  alias DriversSeatCoop.{Accounts, Argyle}
  alias DriversSeatCoop.Earnings.Oban.UpdateTimeSpansForUserWorkday
  alias DriversSeatCoop.Goals.Oban.CalculatePerformanceForUserWindow

  def schedule_jobs(%Date{} = beginning, %Date{} = ending \\ Date.utc_today()) do
    beginning = DateTime.new!(beginning, ~T[00:00:00], "Etc/UTC")
    beginning = Enum.min([beginning, DateTime.utc_now()], DateTime)

    ending =
      Date.add(ending, 1)
      |> DateTime.new!(~T[00:00:00], "Etc/UTC")

    ending = Enum.min([ending, DateTime.utc_now()], DateTime)

    Accounts.list_users_with_argyle_linked()
    |> Enum.each(fn u ->
      new(%{
        user_id: u.id,
        argyle_account_id: u.argyle_user_id,
        from_start_date: beginning,
        to_start_date: ending
      })
      |> Oban.insert()
    end)
  end

  def schedule_job(user_id, argyle_account_id, beginning, ending) do
    new(%{
      user_id: user_id,
      argyle_account_id: argyle_account_id,
      from_start_date: beginning,
      to_start_date: ending
    })
    |> Oban.insert()
  end

  @impl Oban.Worker
  def perform(%Oban.Job{
        id: id,
        args: %{
          "user_id" => user_id,
          "argyle_account_id" => argyle_account_id,
          "from_start_date" => from_start_date,
          "to_start_date" => to_start_date
        }
      }) do
    # get activities for a single user and a single account in a given date range.
    Logger.metadata(oban_job_id: id)

    Logger.info(
      "Getting argyle activities for #{user_id} from #{from_start_date} to #{to_start_date} with account #{argyle_account_id}"
    )

    user = Accounts.get_user!(user_id)

    Argyle.backfill_argyle_activities(user, %{
      account: argyle_account_id,
      from_start_date: from_start_date,
      to_start_date: to_start_date
    })

    # update working time calculations
    UpdateTimeSpansForUserWorkday.schedule_jobs_for_date_range(
      user_id,
      from_start_date,
      to_start_date,
      nil
    )

    # update goal performance calculations
    CalculatePerformanceForUserWindow.schedule_jobs_for_date_range(
      user_id,
      from_start_date,
      to_start_date
    )

    :ok
  end

  @impl Oban.Worker
  def perform(%Oban.Job{id: id}) do
    # get activities for all users as far back as yesterday.
    Logger.metadata(oban_job_id: id)

    env = Application.get_env(:dsc, DriversSeatCoop.Argyle)

    if env[:enable_background_tasks?] do
      Logger.info("Starting cron for argyle activity fetcher")

      yesterday =
        NaiveDateTime.utc_now()
        |> NaiveDateTime.add(-1 * 60 * 60 * 24)

      Accounts.list_users_with_argyle_linked()
      |> Enum.each(fn user ->
        Argyle.backfill_argyle_activities(user, %{from_start_date: yesterday})
      end)
    else
      Logger.info(
        "Skipping cron for argyle activity fetcher. ARGYLE_ENABLE_BACKGROUND_TASKS is not set to true"
      )
    end

    :ok
  end

  @impl Oban.Worker
  def timeout(_job), do: :timer.minutes(30)
end
