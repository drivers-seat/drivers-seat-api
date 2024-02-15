defmodule DriversSeatCoop.Repo.Migrations.AddTimezoneArgyle do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:timezone_argyle, :text)
    end
  end
end
