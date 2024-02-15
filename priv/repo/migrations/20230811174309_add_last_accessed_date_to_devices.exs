defmodule DriversSeatCoop.Repo.Migrations.AddLastAccessedDateToDevices do
  use Ecto.Migration

  def change do
    alter table(:devices) do
      add(:last_access_date, :date)
    end
  end
end
