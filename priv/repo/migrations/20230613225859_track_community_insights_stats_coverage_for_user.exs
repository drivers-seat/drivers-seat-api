defmodule DriversSeatCoop.Repo.Migrations.TrackCommunityInsightsStatsCoverageForUser do
  use Ecto.Migration

  alias DriversSeatCoop.CommunityInsights.CoverageStatsSource

  def change do
    CoverageStatsSource.create_type()

    create table(:community_insights_user_coverage_stats) do
      add(:user_id, references(:users, on_delete: :nothing), null: false)
      add(:calculated_on, :utc_datetime, null: false)
      add(:stats_source, :coverage_stats_source, null: false)
      add(:region_id_metro_area, references(:region_metro_area, on_delete: :nothing), null: true)
      add(:coverage_percent, :decimal, null: false)
      add(:notification_required, :boolean, null: false, default: false)
      add(:notified_on, :utc_datetime)
      timestamps()
    end

    create unique_index(:community_insights_user_coverage_stats, [:user_id],
             name: :community_insights_user_coverage_stats_ak
           )
  end
end
