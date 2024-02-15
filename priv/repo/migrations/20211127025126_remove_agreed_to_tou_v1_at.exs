defmodule DriversSeatCoop.Repo.Migrations.RemoveAgreedToTouV1At do
  use Ecto.Migration

  def change do
    alter table(:users) do
      remove(:agreed_to_tou_v1_at)
    end
  end
end
