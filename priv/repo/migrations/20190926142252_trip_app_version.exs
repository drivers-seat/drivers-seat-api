defmodule DriversSeatCoop.Repo.Migrations.TripAppVersion do
  use Ecto.Migration

  def change do
    alter table(:trips) do
      add :app_version, :text
    end
  end
end
