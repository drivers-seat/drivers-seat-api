defmodule DriversSeatCoop.Repo.Migrations.UsersCountryPostalCode do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :country, :text
      add :postal_code, :text
    end
  end
end
