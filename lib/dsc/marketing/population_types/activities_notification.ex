defmodule DriversSeatCoop.Marketing.PopulationTypes.ActivitiesNotification do
  alias DriversSeatCoop.Accounts.User
  alias DriversSeatCoop.Marketing.PopulationType

  @behaviour PopulationType

  @impl PopulationType
  def get_type_code, do: :exp_activities_notif

  @impl PopulationType
  def get_available_populations, do: [:control, :treatment_7d, :treatment_3d]

  @impl PopulationType
  def select_populations_for_user(%User{}) do
    PopulationType.select_populations_round_robin(get_type_code(), 1)
  end
end
