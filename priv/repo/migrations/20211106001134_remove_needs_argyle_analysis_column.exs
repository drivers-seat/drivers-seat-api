defmodule DriversSeatCoop.Repo.Migrations.RemoveNeedsArgyleAnalysisColumn do
  use Ecto.Migration

  def change do
    alter table(:shifts) do
      remove(:needs_argyle_analysis)
    end
  end
end
