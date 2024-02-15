defmodule DriversSeatCoop.Repo.Migrations.RemoveCurrentlyOnShift do
  use Ecto.Migration

  def change do
    alter table(:users) do
      remove(:currently_on_shift)
    end
  end
end
