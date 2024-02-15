defmodule DriversSeatCoop.Repo.Migrations.DeprecateAnalyticsActivitiesLinkToRefData do
  use Ecto.Migration

  def change do
    alter table(:activities) do
      add(:metro_area_id, references(:region_metro_area, on_delete: :nothing))
      add(:employer_id, references(:employers, on_delete: :nothing))
      add(:service_class_id, references(:service_classes, on_delete: :nothing))
      add(:employer_service_class_id, references(:employer_service_classes, on_delete: :nothing))
      add(:timestamp_insights_work_start, :utc_datetime, null: true)
    end
  end
end
