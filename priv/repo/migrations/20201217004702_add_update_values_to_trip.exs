defmodule DriversSeatCoop.Repo.Migrations.AddUpdateValuesToTrip do
  use Ecto.Migration

  def change do
    alter table(:trips) do
      add :updated_inserted_at, :naive_datetime
      add :updated_user_ended_at, :naive_datetime
      add :updated_passenger_count, :integer
      add :updated_tnc_service_name, :string
    end
  end
end
