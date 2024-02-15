defmodule DriversSeatCoop.Argyle.Oban.RefreshUserGigAccounts do
  @moduledoc """
  This job will attempt to grab new argyle activities for each user with a
  linked argyle account.
  """

  alias DriversSeatCoop.Accounts
  alias DriversSeatCoop.GigAccounts

  use Oban.Worker,
    queue: :argyle_api,
    max_attempts: 2,
    unique: [
      period: :infinity,
      states: [:available, :scheduled],
      keys: [:user_id]
    ]

  require Logger

  def schedule_jobs do
    Accounts.list_users_with_argyle_linked()
    |> Enum.map(fn u -> u.id end)
    |> schedule_jobs()

    :ok
  end

  def schedule_jobs(user_ids) do
    List.wrap(user_ids)
    |> Enum.each(fn u -> schedule_job(u) end)

    :ok
  end

  def schedule_job(user_id) do
    new(%{
      user_id: user_id
    })
    |> Oban.insert()
  end

  @impl Oban.Worker
  def perform(%Oban.Job{
        id: id,
        args: %{
          "user_id" => user_id
        }
      }) do
    # refreshes gig accounts for a single user
    Logger.metadata(oban_job_id: id)

    user = Accounts.get_user!(user_id)

    Logger.info(
      "Refreshing Argyle Gig Accounts for #{user.id} with argyle account #{user.argyle_user_id}"
    )

    GigAccounts.refresh_user_gig_accounts(user)
  end

  @impl Oban.Worker
  def perform(%Oban.Job{id: id}) do
    # refreshes gig accounts for all users with argyle accounts

    Logger.metadata(oban_job_id: id)
    Logger.info("Refreshing Argyle Gig Accounts for all users")

    schedule_jobs()

    :ok
  end

  @impl Oban.Worker
  def timeout(_job), do: :timer.minutes(30)
end
