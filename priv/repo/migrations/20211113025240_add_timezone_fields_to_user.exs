defmodule DriversSeatCoop.Repo.Migrations.AddTimezoneFieldsToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:timezone_device, :text)
      add(:timezone, :text)
    end
  end
end
