defmodule DriversSeatCoop.Repo.Migrations.UserProfiles do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :first_name, :text
      add :last_name, :text
      add :phone_number, :text
      add :vehicle_make, :text
      add :vehicle_model, :text
      add :vehicle_year, :integer
      add :service_names, {:array, :text}
      remove :name
    end
  end
end
