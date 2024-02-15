defmodule DriversSeatCoop.Repo.Migrations.UserDevicePlatform do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :device_platform, :text
    end
  end
end
