defmodule DriversSeatCoop.Repo.Migrations.ExtractFieldsFromActivitiesPart2 do
  use Ecto.Migration

  def change do
    execute(
      "CREATE INDEX IF NOT EXISTS activities_user_id_working_day_start_index ON public.activities(user_id, working_day_start, earning_type, status) include(working_day_end, deleted);"
    )

    execute(
      "CREATE INDEX IF NOT EXISTS activities_user_id_working_day_end_index ON public.activities(user_id, working_day_end, earning_type, status) include(working_day_start, deleted);"
    )
  end
end
