defmodule DriversSeatCoop.Argyle.Oban.RefreshTokens do
  @moduledoc """
  This job will refresh all argyle user tokens in the database.
  """

  use Oban.Worker,
    queue: :argyle_api,
    max_attempts: 1,
    unique: [period: 600]

  require Logger
  alias DriversSeatCoop.{Accounts, Argyle}

  @impl Oban.Worker
  def perform(%Oban.Job{id: id}) do
    Logger.metadata(oban_job_id: id)

    env = Application.get_env(:dsc, DriversSeatCoop.Argyle)

    if env[:enable_background_tasks?] do
      Logger.info("Starting cron for argyle user token refresher")

      Accounts.list_users_with_argyle_linked()
      |> Enum.each(&refresh_token/1)
    else
      Logger.info(
        "Skipping cron for argyle user token refresher. ARGYLE_ENABLE_BACKGROUND_TASKS is not set to true"
      )
    end

    :ok
  end

  defp refresh_token(user) do
    expiration = Argyle.get_token_expiration(user.argyle_token)
    remaining_ttl = DateTime.diff(expiration, DateTime.utc_now())

    # if the token is expiring within the next day, then refresh it
    if remaining_ttl <= 60 * 60 * 24 do
      Argyle.refresh_argyle_user_tokens(user)
    end
  end

  @impl Oban.Worker
  def timeout(_job), do: :timer.minutes(30)
end
