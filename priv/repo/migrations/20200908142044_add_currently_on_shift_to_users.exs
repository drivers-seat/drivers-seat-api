defmodule DriversSeatCoop.Repo.Migrations.AddCurrentlyOnShiftToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :currently_on_shift, :naive_datetime_usec
    end
  end
end
