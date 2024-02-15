defmodule DriversSeatCoop.Repo.Migrations.TrackSensitiveDataOptOut do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:opted_out_of_sensitive_data_use_at, :naive_datetime_usec)
    end
  end
end
