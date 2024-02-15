defmodule DriversSeatCoop.Repo.Migrations.CreateHourlyEarningTable do
  use Ecto.Migration

  def change do
    create table(:hourly_earnings) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :date, :date, null: false
      add :gross_pay, :float
      add :net_pay, :float

      timestamps()
    end
  end
end
