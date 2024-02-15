defmodule DriversSeatCoop.Repo.Migrations.AddOptOutToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :opted_out_of_data_sale_at, :naive_datetime_usec
    end
  end
end
