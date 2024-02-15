defmodule DriversSeatCoop.Repo.Migrations.AddEnrolledAndUnrolledToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :enrolled_research_at, :naive_datetime
      add :unenrolled_research_at, :naive_datetime
    end
  end
end
