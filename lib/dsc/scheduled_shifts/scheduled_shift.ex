defmodule DriversSeatCoop.ScheduledShifts.ScheduledShift do
  use Ecto.Schema
  import Ecto.Changeset

  @required_fields ~w(
    start_day_of_week
    start_time_local
    duration_minutes
  )a

  @optional_fields ~w()a

  schema "scheduled_shifts" do
    field :start_day_of_week, :integer
    field :start_time_local, :time
    field :duration_minutes, :integer

    belongs_to :user, DriversSeatCoop.Accounts.User

    timestamps()
  end

  @doc false
  def changeset(scheduled_shift, attrs) do
    scheduled_shift
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_number(:start_day_of_week,
      greater_than_or_equal_to: 0,
      less_than_or_equal_to: 6
    )
    |> validate_number(:duration_minutes,
      greater_than: 0,
      less_than: 10_080
    )
    |> validate_time_truncated_to_minute(:start_time_local)
    |> assoc_constraint(:user)
  end

  def validate_time_truncated_to_minute(changeset, field) when is_atom(field) do
    validate_change(changeset, field, fn field, value ->
      case value do
        %Time{second: 0, microsecond: {0, 0}} -> []
        _ -> [{field, "values must be precise to the minute"}]
      end
    end)
  end
end
