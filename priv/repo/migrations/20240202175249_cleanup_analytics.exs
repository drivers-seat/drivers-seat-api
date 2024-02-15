defmodule DriversSeatCoop.Repo.Migrations.CleanupAnalytics do
  use Ecto.Migration

  def change do
    drop_if_exists table(:community_insights_user_coverage_stats)
  end
end
