defmodule DriversSeatCoop.Repo.Migrations.AddFrontendMileageToShift do
  use Ecto.Migration

  def change do
    alter table(:shifts) do
      add :frontend_mileage, :float
    end
  end
end
