defmodule DriversSeatCoop.Earnings.TimespanAllocation do
  use Ecto.Schema
  import Ecto.Changeset
  alias DriversSeatCoop.Util.MapUtil
  alias DriversSeatCoop.Util.MathUtil

  @required_fields ~w(
    start_time
    end_time
    duration_seconds
  )a

  @optional_fields ~w(
    timespan_id
    activity_id
    activity_coverage_percent
    activity_extends_before
    activity_extends_after
    device_miles
    device_miles_deduction_cents
    device_miles_quality_percent
    platform_miles
    platform_miles_per_second
  )a

  schema "timespan_allocations" do
    field :start_time, :utc_datetime
    field :end_time, :utc_datetime
    field :duration_seconds, :integer
    field :activity_coverage_percent, :decimal
    field :activity_extends_before, :boolean
    field :activity_extends_after, :boolean
    field :device_miles, :decimal
    field :device_miles_deduction_cents, :integer
    field :device_miles_quality_percent, :decimal
    field :platform_miles, :decimal
    field :platform_miles_per_second, :decimal

    belongs_to :timespan, DriversSeatCoop.Earnings.Timespan
    belongs_to :activity, DriversSeatCoop.Activities.Activity

    timestamps()
  end

  def changeset(alloc, attrs) do
    attrs =
      attrs
      |> MapUtil.replace(:activity_coverage_percent, fn v -> MathUtil.round(v, 3) end)
      |> MapUtil.replace(:device_miles_quality_percent, fn v -> MathUtil.round(v, 3) end)
      |> MapUtil.replace(:device_miles, fn v -> MathUtil.round(v, 1) end)
      |> MapUtil.replace(:platform_miles_quality_percent, fn v -> MathUtil.round(v, 3) end)
      |> MapUtil.replace(:platform_miles, fn v -> MathUtil.round(v, 1) end)

    alloc
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_number(:duration_seconds,
      greater_than_or_equal_to: 0,
      less_than_or_equal_to: 86_400
    )
    |> validate_number(:device_miles, greater_than_or_equal_to: 0)
    |> validate_number(:device_miles_deduction_cents, greater_than_or_equal_to: 0)
    |> validate_number(:device_miles_quality_percent,
      greater_than_or_equal_to: 0,
      less_than_or_equal_to: 1
    )
    |> validate_number(:platform_miles, greater_than_or_equal_to: 0)
    |> validate_number(:platform_miles_per_second, greater_than_or_equal_to: 0)
    |> assoc_constraint(:timespan)
    |> assoc_constraint(:activity)
  end
end
