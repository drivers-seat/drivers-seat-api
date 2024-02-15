defmodule DriversSeatCoop.Argyle.Oban.ImportArgyleProfileInformation do
  @moduledoc """
  This job will import profile information from Argyle for a given user
  """

  use Oban.Worker,
    queue: :argyle_api,
    max_attempts: 5,
    unique: [period: 600]

  require Logger
  alias DriversSeatCoop.Accounts

  def schedule_job(user_id) do
    new(%{user_id: user_id})
    |> Oban.insert()
  end

  @impl Oban.Worker
  def perform(%Oban.Job{id: id, args: %{"user_id" => user_id}}) do
    Logger.metadata(oban_job_id: id)
    Logger.info("Importing profile info for #{user_id}")

    user = Accounts.get_user!(user_id)
    {:ok, _} = DriversSeatCoop.Argyle.import_argyle_profile_information(user)

    :ok
  end

  @impl Oban.Worker
  def timeout(_job), do: :timer.minutes(30)
end
