defmodule DriversSeatCoop.Marketing.PopulationTypes.OnboardingWelcome do
  alias DriversSeatCoop.Accounts.User
  alias DriversSeatCoop.Marketing.PopulationType

  @behaviour PopulationType

  @impl PopulationType
  def get_type_code, do: :exp_onboarding_welcome

  @impl PopulationType
  def get_available_populations, do: [:display_welcome, :do_not_display_welcome]

  @impl PopulationType
  def select_populations_for_user(%User{}) do
    PopulationType.select_populations_round_robin(get_type_code(), 1)
  end
end
