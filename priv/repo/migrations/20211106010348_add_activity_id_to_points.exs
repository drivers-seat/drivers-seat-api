defmodule DriversSeatCoop.Repo.Migrations.AddActivityIdToPoints do
  use Ecto.Migration

  def change do
    alter table(:points) do
      add(:argyle_activity_id, references(:activities, on_delete: :nothing))
    end
  end
end
