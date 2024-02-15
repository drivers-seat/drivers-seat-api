defmodule DriversSeatCoop.Repo.Migrations.AddAdditionalArgyleToTrip do
  use Ecto.Migration

  def change do
    alter table(:trips) do
      add :accepted_time, :naive_datetime_usec
      add :is_argyle, :boolean
    end
  end
end
