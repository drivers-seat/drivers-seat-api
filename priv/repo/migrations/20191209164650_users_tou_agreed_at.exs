defmodule DriversSeatCoop.Repo.Migrations.UsersTouAgreedAt do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :agreed_to_tou_v1_at, :naive_datetime_usec
    end
  end
end
