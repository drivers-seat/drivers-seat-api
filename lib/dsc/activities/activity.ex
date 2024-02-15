defmodule DriversSeatCoop.Activities.Activity do
  use Ecto.Schema
  import Ecto.Changeset
  alias DriversSeatCoop.Accounts.User
  alias DriversSeatCoop.Employers
  alias DriversSeatCoop.Employers.Employer
  alias DriversSeatCoop.Regions
  alias DriversSeatCoop.Regions.MetroArea
  alias DriversSeatCoop.Util.DateTimeUtil
  require Logger

  @not_avail :not_in_changeset
  @empty_cache %{}

  @required_fields ~w(activity_id user_id)a
  @optional_fields ~w(
    activity_data
    date
    deleted
    service_class
    currency
    employer
    employer_service
    data_partner
    earning_type
    income_rate_hour_cents
    income_rate_mile_cents
    status
    distance
    distance_unit
    duration_seconds
    timezone
    timestamp_start
    timestamp_end
    timestamp_request
    timestamp_accept
    timestamp_cancel
    timestamp_pickup
    timestamp_dropoff
    timestamp_shift_start
    timestamp_shift_end
    is_pool
    is_rush
    is_surge
    start_location_lat
    start_location_lon
    start_location_address
    end_location_lat
    end_location_lon
    end_location_address
    earnings_pay_cents
    earnings_tip_cents
    earnings_bonus_cents
    earnings_total_cents
    charges_fees_cents
    charges_taxes_cents
    charges_total_cents
    tasks_total
    notification_required
    notified_on

    timestamp_work_start
    timestamp_work_end
    working_day_start
    working_day_end
    timestamp_insights_work_start
    metro_area_id
    employer_id
    service_class_id
    employer_service_class_id
  )a

  schema "activities" do
    field :activity_id, :string
    field :activity_data, :map
    field :date, :utc_datetime_usec
    field :deleted, :boolean, default: false

    field :service_class, :string

    field :employer, :string
    field :employer_service, :string
    field :data_partner, :string
    field :earning_type, :string
    field :currency, :string

    field :income_rate_hour_cents, :integer
    field :income_rate_mile_cents, :integer

    field :status, :string

    field :distance, :decimal
    field :distance_unit, :string

    field :duration_seconds, :integer

    field :timezone, :string
    field :timestamp_start, :utc_datetime
    field :timestamp_end, :utc_datetime
    field :timestamp_request, :utc_datetime
    field :timestamp_accept, :utc_datetime
    field :timestamp_cancel, :utc_datetime
    field :timestamp_pickup, :utc_datetime
    field :timestamp_dropoff, :utc_datetime
    field :timestamp_shift_start, :utc_datetime
    field :timestamp_shift_end, :utc_datetime

    field :is_pool, :boolean
    field :is_rush, :boolean
    field :is_surge, :boolean

    field :start_location_lat, :float, virtual: true
    field :start_location_lon, :float, virtual: true
    field :start_location_geometry, Geo.PostGIS.Geometry
    field :start_location_address, :string

    field :end_location_lat, :float, virtual: true
    field :end_location_lon, :float, virtual: true
    field :end_location_geometry, Geo.PostGIS.Geometry
    field :end_location_address, :string

    field :earnings_pay_cents, :integer
    field :earnings_tip_cents, :integer
    field :earnings_bonus_cents, :integer
    field :earnings_total_cents, :integer

    field :charges_fees_cents, :integer
    field :charges_taxes_cents, :integer
    field :charges_total_cents, :integer

    field :working_day_start, :date
    field :working_day_end, :date
    field :timestamp_work_start, :utc_datetime
    field :timestamp_work_end, :utc_datetime

    field :tasks_total, :integer

    field :notification_required, :boolean
    field :notified_on, :utc_datetime

    field :timestamp_insights_work_start, :utc_datetime

    belongs_to(:user, User)
    belongs_to(:employer_ref, Employer, foreign_key: :employer_id)
    belongs_to(:service_class_ref, Employer, foreign_key: :service_class_id)
    belongs_to(:employer_service_class_ref, Employer, foreign_key: :employer_service_class_id)
    belongs_to(:metro_area, MetroArea)

    has_many :allocations, DriversSeatCoop.Earnings.TimespanAllocation, on_delete: :delete_all

    timestamps()
  end

  def changeset(
        activity,
        user,
        attrs
      ) do
    {changeset, _, _, _} =
      changeset(activity, user, attrs, @empty_cache, @empty_cache, @empty_cache)

    changeset
  end

  def changeset(
        activity,
        user,
        attrs,
        %{} = cache_service_classes,
        %{} = cache_employers,
        %{} = cache_employer_service_classes
      ) do
    changeset =
      activity
      |> cast(attrs, @required_fields ++ @optional_fields)
      |> validate_required(@required_fields)
      |> assoc_constraint(:user)

    {changeset, cache_service_classes} = cast_service_class(changeset, cache_service_classes)
    {changeset, cache_employers} = cast_employer(changeset, cache_employers)

    {changeset, cache_employer_service_classes} =
      cast_employer_service_class(changeset, cache_employer_service_classes)

    changeset =
      changeset
      |> assoc_constraint(:employer_ref)
      |> cast_start_location_geometry()
      |> cast_end_location_geometry()
      |> cast_metro_area(user)
      |> assoc_constraint(:metro_area)
      |> cast_timestamp_work_start()
      |> cast_timestamp_work_end()
      |> handle_incomplete_times_with_duration()
      |> cast_work_date_start(user)
      |> cast_work_date_end(user)
      |> cast_insights_work_time_start()
      |> unique_constraint(:activity_id, name: "activities_activity_id_index")

    {changeset, cache_service_classes, cache_employers, cache_employer_service_classes}
  end

  def notification_changeset(activity, attrs) do
    activity
    |> cast(attrs, [:notification_required, :notified_on])
  end

  defp cast_start_location_geometry(changeset) do
    latitude = get_change(changeset, :start_location_lat, @not_avail)
    longitude = get_change(changeset, :start_location_lon, @not_avail)

    cond do
      latitude == @not_avail and longitude == @not_avail ->
        changeset

      is_nil(latitude) or is_nil(longitude) ->
        cast(changeset, %{start_location_geometry: nil}, [:start_location_geometry])

      true ->
        json = Geo.JSON.encode(%Geo.Point{coordinates: {longitude, latitude}, srid: 4326})
        cast(changeset, %{start_location_geometry: json}, [:start_location_geometry])
    end
  end

  defp cast_end_location_geometry(changeset) do
    latitude = get_change(changeset, :end_location_lat, @not_avail)
    longitude = get_change(changeset, :end_location_lon, @not_avail)

    cond do
      latitude == @not_avail and longitude == @not_avail ->
        changeset

      is_nil(latitude) or is_nil(longitude) ->
        cast(changeset, %{end_location_geometry: nil}, [:end_location_geometry])

      true ->
        json = Geo.JSON.encode(%Geo.Point{coordinates: {longitude, latitude}, srid: 4326})
        cast(changeset, %{end_location_geometry: json}, [:end_location_geometry])
    end
  end

  defp cast_timestamp_work_start(changeset) do
    dtms =
      [
        get_field(changeset, :timestamp_pickup),
        get_field(changeset, :timestamp_start)
      ]
      |> Enum.filter(fn d -> not is_nil(d) end)

    work_start = Enum.at(dtms, 0)

    cast(changeset, %{timestamp_work_start: work_start}, [:timestamp_work_start])
  end

  defp cast_timestamp_work_end(changeset) do
    dtms =
      [
        get_field(changeset, :timestamp_dropoff),
        get_field(changeset, :timestamp_cancel),
        get_field(changeset, :timestamp_end)
      ]
      |> Enum.filter(fn d -> not is_nil(d) end)

    work_end = Enum.at(dtms, 0)

    cast(changeset, %{timestamp_work_end: work_end}, [:timestamp_work_end])
  end

  defp handle_incomplete_times_with_duration(changeset) do
    duration = get_field(changeset, :duration_seconds)
    work_start = get_field(changeset, :timestamp_work_start)
    work_end = get_field(changeset, :timestamp_work_end)

    cond do
      # has start + duration but not end
      not is_nil(work_start) and is_nil(work_end) and not is_nil(duration) ->
        work_end = DateTime.add(work_start, duration, :second)
        cast(changeset, %{timestamp_work_end: work_end}, [:timestamp_work_end])

      # has end + duration, but not start
      is_nil(work_start) and not is_nil(work_end) and not is_nil(duration) ->
        work_start = DateTime.add(work_end, 0 - duration, :second)
        cast(changeset, %{timestamp_work_start: work_start}, [:timestamp_work_start])

      true ->
        changeset
    end
  end

  defp cast_work_date_start(changeset, user) do
    timezone = get_field(changeset, :timezone) || User.timezone(user)
    time = get_field(changeset, :timestamp_work_start)

    local_date =
      if is_nil(timezone) or is_nil(time),
        do: nil,
        else: DateTimeUtil.datetime_to_working_day(time, timezone)

    cast(changeset, %{working_day_start: local_date}, [:working_day_start])
  end

  defp cast_work_date_end(changeset, user) do
    timezone = get_field(changeset, :timezone) || User.timezone(user)
    time = get_field(changeset, :timestamp_work_end)

    local_date =
      if is_nil(timezone) or is_nil(time),
        do: nil,
        else: DateTimeUtil.datetime_to_working_day(time, timezone)

    cast(changeset, %{working_day_end: local_date}, [:working_day_end])
  end

  # credo:disable-for-next-line
  defp cast_employer(changeset, cache = %{}) do
    has_changes_employer = get_change(changeset, :employer, @not_avail) != @not_avail
    has_changes_data_partner = get_change(changeset, :data_partner, @not_avail) != @not_avail
    has_changes = has_changes_employer or has_changes_data_partner

    employer_name = get_field(changeset, :employer)
    data_partner = get_field(changeset, :data_partner)
    employer_id = get_field(changeset, :employer_id)

    cache_employer_id =
      Map.get(cache, employer_name || data_partner, Map.get(cache, data_partner))

    employer_id =
      cond do
        not is_nil(cache_employer_id) ->
          cache_employer_id

        # something is change, have to do the lookup
        has_changes ->
          Map.get(
            Employers.get_or_create_employer(employer_name || data_partner, data_partner) || %{},
            :id
          )

        # employer is empty, set null and let change detector deal with it
        is_nil(employer_name) ->
          nil

        # there is an employer, but not an id, do the lookup
        is_nil(employer_id) ->
          Map.get(
            Employers.get_or_create_employer(employer_name || data_partner, data_partner) || %{},
            :id
          )

        # otherwise, keep existing value
        true ->
          employer_id
      end

    changeset = cast(changeset, %{employer_id: employer_id}, [:employer_id])

    cache =
      if is_nil(employer_name),
        do: cache,
        else: Map.put(cache, employer_name, employer_id)

    cache =
      if is_nil(data_partner),
        do: cache,
        else: Map.put(cache, data_partner, employer_id)

    {changeset, cache}
  end

  defp cast_service_class(changeset, %{} = cache) do
    has_changes = get_change(changeset, :service_class, @not_avail) != @not_avail
    service_class_name = get_field(changeset, :service_class)
    service_class_id = get_field(changeset, :service_class_id)

    cache_service_class_id = Map.get(cache, service_class_name)

    service_class_id =
      cond do
        not is_nil(cache_service_class_id) ->
          cache_service_class_id

        # something is change, have to do the lookup
        has_changes ->
          Map.get(Employers.get_or_create_service_class(service_class_name) || %{}, :id)

        # service class is empty, set null and let change detector deal with it
        is_nil(service_class_name) ->
          nil

        # there is service class but no ID, backfill the id using lookup
        is_nil(service_class_id) ->
          Map.get(Employers.get_or_create_service_class(service_class_name) || %{}, :id)

        true ->
          service_class_id
      end

    cache = Map.put(cache, service_class_name, service_class_id)
    changeset = cast(changeset, %{service_class_id: service_class_id}, [:service_class_id])

    {changeset, cache}
  end

  # credo:disable-for-next-line
  defp cast_employer_service_class(changeset, %{} = cache) do
    has_change_employer = get_change(changeset, :employer_id, @not_avail) != @not_avail
    has_change_service_class = get_change(changeset, :service_class_id, @not_avail) != @not_avail
    employer_id = get_field(changeset, :employer_id)
    service_class_id = get_field(changeset, :service_class_id)
    employer_service_class_id = get_field(changeset, :employer_service_class_id)

    cache_key = "#{service_class_id}_#{employer_id}"
    cache_employer_service_class_id = Map.get(cache, cache_key)

    employer_service_class_id =
      cond do
        not is_nil(cache_employer_service_class_id) ->
          cache_employer_service_class_id

        # something changed, do lokup
        has_change_employer or has_change_service_class ->
          Map.get(
            Employers.get_or_create_employer_service_class(service_class_id, employer_id) || %{},
            :id
          )

        # null value, set null and let change detector deal with it.
        is_nil(employer_id) or is_nil(service_class_id) ->
          nil

        # values present, do backfill lookup
        is_nil(employer_service_class_id) ->
          Map.get(
            Employers.get_or_create_employer_service_class(service_class_id, employer_id) || %{},
            :id
          )

        true ->
          employer_service_class_id
      end

    changeset =
      cast(changeset, %{employer_service_class_id: employer_service_class_id}, [
        :employer_service_class_id
      ])

    cache = Map.put(cache, cache_key, employer_service_class_id)

    {changeset, cache}
  end

  # credo:disable-for-next-line
  defp cast_metro_area(changeset, user) do
    has_changes_start = get_change(changeset, :start_location_geometry, @not_avail) != @not_avail
    has_changes_end = get_change(changeset, :end_location_geometry, @not_avail) != @not_avail
    has_changes = has_changes_start or has_changes_end

    start_loc = get_field(changeset, :start_location_geometry)
    end_loc = get_field(changeset, :end_location_geometry)
    metro_area_id = get_field(changeset, :metro_area_id)

    match_metro_area_id =
      cond do
        # if there has been loc changes, we have to do the lookup
        has_changes ->
          Regions.get_metro_area_id_for_point(start_loc) ||
            Regions.get_metro_area_id_for_point(end_loc)

        # if there are no locations, set metro to nil
        is_nil(start_loc || end_loc) ->
          nil

        # if there are locations and metro is nil, do the lookup
        is_nil(metro_area_id) ->
          Regions.get_metro_area_id_for_point(start_loc) ||
            Regions.get_metro_area_id_for_point(end_loc)

        # otherwise maintain prior value
        true ->
          metro_area_id
      end

    cast(changeset, %{metro_area_id: match_metro_area_id || user.metro_area_id}, [:metro_area_id])
  end

  defp cast_insights_work_time_start(changeset) do
    engaged_start = get_field(changeset, :timestamp_work_start)
    engaged_end = get_field(changeset, :timestamp_work_end)

    job_dtms =
      [
        # favor accept over request
        get_field(changeset, :timestamp_accept) || get_field(changeset, :timestamp_request),
        engaged_start
      ]
      |> Enum.filter(fn d -> not is_nil(d) end)

    # not enough information to calculate work_start
    timestamp_insights_work_start =
      if is_nil(engaged_start) or is_nil(engaged_end) or not Enum.any?(job_dtms) do
        nil
      else
        # the request and accept dates may be misleading.  Services, such as grubhub, have requests that occur
        # days in advance.  If we use these days to calculate non_engaged time, the hourly rate would be
        # skewed very low.  So, for insights purposes, never condsider more than 2x the working time to be the
        # non_engaged work time for the job.
        engaged_duration = Enum.max([DateTime.diff(engaged_end, engaged_start), 0])
        min_possible_work_start = DateTime.add(engaged_start, 0 - engaged_duration * 2, :second)

        Enum.max([Enum.min(job_dtms, DateTime), min_possible_work_start], DateTime)
      end

    cast(changeset, %{timestamp_insights_work_start: timestamp_insights_work_start}, [
      :timestamp_insights_work_start
    ])
  end
end
