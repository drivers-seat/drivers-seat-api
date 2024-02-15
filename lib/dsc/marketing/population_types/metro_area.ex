defmodule DriversSeatCoop.Marketing.PopulationTypes.MetroArea do
  alias DriversSeatCoop.Accounts.User
  alias DriversSeatCoop.Marketing.PopulationType
  alias DriversSeatCoop.Regions

  @behaviour PopulationType

  @impl PopulationType
  def get_type_code, do: :metro_area

  @impl PopulationType
  def get_available_populations do
    Regions.get_metro_areas()
    |> Enum.map(fn ma -> String.to_atom(ma.name) end)
    |> List.insert_at(0, :unknown)
  end

  @impl PopulationType
  def select_populations_for_user(%User{} = user) do
    metro_area = Regions.get_metro_area_for_user(user)

    if is_nil(metro_area) do
      []
    else
      [String.to_atom(metro_area.name)]
    end
  end
end
