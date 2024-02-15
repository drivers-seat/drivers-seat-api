defmodule DriversSeatCoop.Repo.Migrations.AddCarOwndershipToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :car_ownership, :text
    end
  end
end
