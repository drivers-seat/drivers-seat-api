defmodule DriversSeatCoop.Marketing.PopulationType do
  alias DriversSeatCoop.Accounts.User
  alias DriversSeatCoop.Marketing

  # Gets the population type
  @callback get_type_code() :: atom()

  # Gets all possible populations of a type
  @callback get_available_populations() :: list(atom())

  # Assigns a user to one or many populations of the type
  @callback select_populations_for_user(%User{}) :: list(atom())

  @doc """
  Assigns populations using a round-robin strategy based on least popular
  """
  def select_populations_round_robin(population_type, count_assignments \\ 1) do
    population_type = Marketing.get_population_type(population_type)
    population_type_code = population_type.get_type_code()

    Marketing.get_population_member_counts(population_type_code)
    |> Map.to_list()
    |> Enum.sort_by(fn {_pop, cnt} -> {cnt, :rand.uniform(5000)} end)
    |> Enum.take(count_assignments)
    |> Enum.map(fn {pop, _cnt} -> pop end)
  end
end
