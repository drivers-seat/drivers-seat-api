defmodule DriversSeatCoop.Marketing.Oban.UpdatePopulationMemberships do
  @moduledoc """
  This job will auto-update memberships in populations
  """

  use Oban.Worker,
    queue: :marketing,
    unique: [
      period: :infinity,
      states: [:available, :scheduled],
      keys: [:user_id]
    ],
    max_attempts: 3

  import Ecto.Query, warn: false

  require Logger
  alias DriversSeatCoop.Accounts
  alias DriversSeatCoop.Marketing
  alias DriversSeatCoop.Marketing.PopulationTypes.MetroArea
  alias DriversSeatCoop.Repo

  @population_types_to_auto_update [
    MetroArea
  ]

  @doc """
  Schedule the job for all users
  """
  def schedule_job do
    Accounts.get_users_query()
    |> select([u], u.id)
    |> Repo.all()
    |> schedule_job()
  end

  @doc """
  Schedule the job for specific user or users
  """
  def schedule_job(user_ids) do
    List.wrap(user_ids)
    |> Enum.each(fn u -> Oban.insert(new(%{user_id: u})) end)
  end

  @impl Oban.Worker
  def perform(%Oban.Job{
        id: id,
        args: %{"user_id" => user_id}
      }) do
    Logger.metadata(oban_job_id: id)
    Logger.info("Updating Population Memberships for User #{user_id}")

    user = Accounts.get_user!(user_id)

    result = %{}

    result =
      Enum.reduce(@population_types_to_auto_update, result, fn pop_type, result ->
        pop_type_code = pop_type.get_type_code()
        populations = Marketing.assign_populations_to_user(user, pop_type_code, true, true)
        population_codes = Enum.map(populations, fn pop -> pop.population end) |> Enum.sort()
        Map.put(result, pop_type_code, population_codes)
      end)

    {:ok, result}
  end

  @impl Oban.Worker
  def perform(%Oban.Job{id: _id}) do
    schedule_job()
    :ok
  end

  @impl Oban.Worker
  def timeout(_job), do: :timer.minutes(5)
end
