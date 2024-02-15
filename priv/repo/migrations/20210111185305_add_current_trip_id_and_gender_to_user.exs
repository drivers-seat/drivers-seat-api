defmodule DriversSeatCoop.Repo.Migrations.AddCurrentTripIdAndGenderToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :current_trip_id, :integer
      add :gender, :text
    end
  end
end
