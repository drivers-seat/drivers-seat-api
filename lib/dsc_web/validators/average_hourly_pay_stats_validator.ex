defmodule DriversSeatCoopWeb.AverageHourlyPayStatsValidator do
  alias Ecto.Changeset

  def summary(params) do
    fields = %{
      metro_area_id: :integer,
      employer_ids: {:array, :integer},
      service_class_ids: {:array, :integer}
    }

    data = %{}

    changeset =
      {data, fields}
      |> Changeset.cast(
        params,
        [
          :metro_area_id,
          :employer_ids,
          :service_class_ids
        ]
      )
      |> Changeset.validate_required([:metro_area_id])

    Changeset.apply_action(changeset, :insert)
  end

  def trend(params) do
    fields = %{
      metro_area_id: :integer,
      day_of_week: :integer,
      hour_of_day: :integer,
      employer_ids: {:array, :integer},
      service_class_ids: {:array, :integer}
    }

    data = %{}

    changeset =
      {data, fields}
      |> Changeset.cast(
        params,
        [
          :metro_area_id,
          :employer_ids,
          :service_class_ids,
          :day_of_week,
          :hour_of_day
        ]
      )
      |> Changeset.validate_required([:metro_area_id, :day_of_week, :hour_of_day])

    Changeset.apply_action(changeset, :insert)
  end
end
