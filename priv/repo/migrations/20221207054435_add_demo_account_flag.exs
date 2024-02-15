defmodule DriversSeatCoop.Repo.Migrations.AddDemoAccountFlag do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:is_demo_account, :boolean, default: false)
    end
  end
end
