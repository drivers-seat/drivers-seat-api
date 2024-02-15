defmodule DriversSeatCoop.Repo.Migrations.AddEthnicityOptionToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :ethnicity, {:array, :text}
    end
  end
end
