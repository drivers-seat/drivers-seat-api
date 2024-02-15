defmodule DriversSeatCoop.Earnings.Timespan do
  use Ecto.Schema
  import Ecto.Changeset

  alias DriversSeatCoop.Earnings.TimespanAllocation
  alias DriversSeatCoop.Earnings.TimespanCalcMethod
  alias DriversSeatCoop.Util.MapUtil
  alias DriversSeatCoop.Util.MathUtil

  @required_fields ~w(
    calc_method
    work_date
    start_time
    end_time
    duration_seconds
    duration_seconds_engaged
  )a

  @optional_fields ~w(
    shift_ids
    device_miles
    device_miles_engaged
    device_miles_deduction_cents
    device_miles_deduction_cents_engaged
    device_miles_quality_percent
    platform_miles
    platform_miles_engaged
    platform_miles_deduction_cents
    platform_miles_deduction_cents_engaged
    platform_miles_quality_percent
    selected_miles
    selected_miles_engaged
    selected_miles_deduction_cents
    selected_miles_deduction_cents_engaged
    selected_miles_quality_percent
  )a

  schema "timespans" do
    field :start_time, :utc_datetime
    field :end_time, :utc_datetime
    field :calc_method, TimespanCalcMethod
    field :work_date, :date
    field :duration_seconds, :integer
    field :duration_seconds_engaged, :integer
    field :shift_ids, {:array, :integer}
    field :device_miles, :decimal
    field :device_miles_engaged, :decimal
    field :device_miles_deduction_cents, :integer
    field :device_miles_deduction_cents_engaged, :integer
    field :device_miles_quality_percent, :decimal
    field :platform_miles, :decimal
    field :platform_miles_engaged, :decimal
    field :platform_miles_deduction_cents, :integer
    field :platform_miles_deduction_cents_engaged, :integer
    field :platform_miles_quality_percent, :decimal
    field :selected_miles, :decimal
    field :selected_miles_engaged, :decimal
    field :selected_miles_deduction_cents, :integer
    field :selected_miles_deduction_cents_engaged, :integer
    field :selected_miles_quality_percent, :decimal

    belongs_to :user, DriversSeatCoop.Accounts.User
    has_many :allocations, DriversSeatCoop.Earnings.TimespanAllocation, on_delete: :delete_all

    timestamps()
  end

  def changeset(timespan, attrs) do
    attrs =
      attrs
      |> MapUtil.replace(:device_miles_quality_percent, fn v -> MathUtil.round(v, 3) end)
      |> MapUtil.replace(:device_miles, fn v -> MathUtil.round(v, 1) end)
      |> MapUtil.replace(:device_miles_engaged, fn v -> MathUtil.round(v, 1) end)
      |> MapUtil.replace(:platform_miles_quality_percent, fn v -> MathUtil.round(v, 3) end)
      |> MapUtil.replace(:platform_miles, fn v -> MathUtil.round(v, 1) end)
      |> MapUtil.replace(:platform_miles_engaged, fn v -> MathUtil.round(v, 1) end)
      |> MapUtil.replace(:selected_miles_quality_percent, fn v -> MathUtil.round(v, 3) end)
      |> MapUtil.replace(:selected_miles, fn v -> MathUtil.round(v, 1) end)
      |> MapUtil.replace(:selected_miles_engaged, fn v -> MathUtil.round(v, 1) end)

    timespan
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_number(:duration_seconds,
      greater_than_or_equal_to: 0,
      less_than_or_equal_to: 86_400
    )
    |> validate_number(:duration_seconds_engaged,
      greater_than_or_equal_to: 0,
      less_than_or_equal_to: 86_400
    )
    |> validate_number(:device_miles, greater_than_or_equal_to: 0)
    |> validate_number(:device_miles_engaged, greater_than_or_equal_to: 0)
    |> validate_number(:device_miles_quality_percent,
      greater_than_or_equal_to: 0,
      less_than_or_equal_to: 1
    )
    |> validate_number(:platform_miles, greater_than_or_equal_to: 0)
    |> validate_number(:platform_miles_engaged, greater_than_or_equal_to: 0)
    |> validate_number(:platform_miles_quality_percent,
      greater_than_or_equal_to: 0,
      less_than_or_equal_to: 1
    )
    |> validate_number(:selected_miles, greater_than_or_equal_to: 0)
    |> validate_number(:selected_miles_engaged, greater_than_or_equal_to: 0)
    |> validate_number(:selected_miles_quality_percent,
      greater_than_or_equal_to: 0,
      less_than_or_equal_to: 1
    )
    |> assoc_constraint(:user)
    |> unique_constraint([:user_id, :start_time],
      name: "timespans_user_calc_method_start_time_key"
    )
  end

  def changeset(timespan, attrs, allocations) do
    changeset = changeset(timespan, attrs)

    allocations =
      Enum.map(allocations, fn alloc ->
        TimespanAllocation.changeset(%TimespanAllocation{}, alloc)
      end)

    changeset
    |> put_assoc(:allocations, allocations)
  end
end
