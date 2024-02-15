defmodule DriversSeatCoop.Repo.Migrations.CommunityInsightsPerfIndexes do
  use Ecto.Migration

  def change do
    # CREATE INDEX CONCURRENTLY activities_index_metro_day_deleted_user_employer_service_class
    # ON activities(metro_area_id, working_day_start, deleted, user_id, employer_service_class_id)

    create_if_not_exists(
      index(
        :activities,
        [:metro_area_id, :working_day_start, :deleted, :user_id, :employer_service_class_id],
        name: :activities_index_metro_day_deleted_user_employer_service_class
      )
    )

    # CREATE INDEX CONCURRENTLY activity_hours_index_week_start_date_day_of_week_hour_local
    # ON activity_hours(week_start_date, day_of_week, hour_local)

    create_if_not_exists(
      index(:activity_hours, [:week_start_date, :day_of_week, :hour_local],
        name: :activity_hours_index_week_start_date_day_of_week_hour_local
      )
    )

    # CREATE INDEX CONCURRENTLY activities_index_user_id_working_day_start_deleted_earning_type_status
    # ON activities(user_id, working_day_start, deleted, earning_type, status) INCLUDE (timezone)

    create_if_not_exists(
      index(
        :activities,
        [:user_id, :working_day_start, :deleted, :earning_type, :status],
        name: :activities_index_user_id_working_day_start_deleted_earning_type_status,
        include: [:timezone]
      )
    )
  end
end
