defmodule DriversSeatCoop.Activities.ActivityHour do
  use Ecto.Schema
  import Ecto.Changeset

  alias DriversSeatCoop.Activities.Activity

  @zero Decimal.new(0)
  @one Decimal.new(1)

  @required_fields ~w(
    activity_id
    date_local
    week_start_date
    day_of_week
    hour_local
    percent_of_activity
    duration_seconds
    earnings_total_cents
  )a

  @optional_fields ~w(
    distance_miles
    deduction_mileage_cents
  )a

  schema "activity_hours" do
    # This is not normalized based on 4am cutoff
    field :date_local, :date
    field :week_start_date, :date
    field :day_of_week, :integer
    field :hour_local, :time
    field :percent_of_activity, :float
    field :duration_seconds, :integer
    field :earnings_total_cents, :integer
    field :distance_miles, :decimal
    field :deduction_mileage_cents, :integer
    belongs_to(:activity, Activity)
    timestamps()
  end

  def changeset(activity_hour, attrs) do
    activity_hour
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_number(:percent_of_activity, greater_than: @zero, less_than_or_equal_to: @one)
    |> validate_number(:day_of_week, greater_than_or_equal_to: 0, less_than_or_equal_to: 6)
    |> validate_number(:duration_seconds, greater_than: 0)
    |> validate_number(:earnings_total_cents, greater_than_or_equal_to: 0)
    |> validate_number(:distance_miles, greater_than_or_equal_to: @zero)
    |> validate_number(:deduction_mileage_cents, greater_than_or_equal_to: 0)
    |> validate_time_truncated_to_hour(:hour_local)
    |> assoc_constraint(:activity)
    |> unique_constraint([:activity_id, :date_local, :hour_local],
      name: "activity_hours_ak"
    )
  end

  def validate_time_truncated_to_hour(changeset, field) when is_atom(field) do
    validate_change(changeset, field, fn field, value ->
      case value do
        %Time{minute: 0, second: 0, microsecond: {0, 0}} -> []
        _ -> [{field, "values must be precise to the hour"}]
      end
    end)
  end
end
