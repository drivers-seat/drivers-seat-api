defmodule DriversSeatCoop.Repo.Migrations.TripsUserEndedAt do
  use Ecto.Migration

  def change do
    alter table(:trips) do
      add :user_ended_at, :naive_datetime
    end
  end
end
