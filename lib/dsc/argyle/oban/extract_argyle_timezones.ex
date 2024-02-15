defmodule DriversSeatCoop.Argyle.Oban.ExtractArgyleTimezones do
  @moduledoc """
  This job will extract timezones from the argyle activities table and fill in
  the timezone_argyle column in the users table.
  """

  use Oban.Worker,
    queue: :argyle_api,
    max_attempts: 1,
    unique: [period: 600]

  require Logger

  alias DriversSeatCoop.Accounts
  alias DriversSeatCoop.Activities

  import Ecto.Query, warn: false

  @impl Oban.Worker
  def perform(%Oban.Job{id: id}) do
    Logger.metadata(oban_job_id: id)
    Logger.info("Starting cron for argyle timezone extractor")

    Activities.get_most_popular_timezone_for_all_users()
    |> Enum.each(fn x ->
      user = Accounts.get_user!(x.user_id)
      Accounts.update_user(user, %{timezone_argyle: x.timezone})
    end)

    :ok
  end

  @impl Oban.Worker
  def timeout(_job), do: :timer.minutes(30)
end
