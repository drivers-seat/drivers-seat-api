defmodule DriversSeatCoop.Repo.Migrations.ChangeCurrnetlyOnShiftToNumber do
  use Ecto.Migration

  def change do
    alter table(:users) do
      remove :currently_on_shift
      add :currently_on_shift, :integer
    end
  end
end
