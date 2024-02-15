defmodule DriversSeatCoop.Shifts do
  import Ecto.Query, warn: false
  alias DriversSeatCoop.Accounts.User
  alias DriversSeatCoop.Activities
  alias DriversSeatCoop.Repo
  alias DriversSeatCoop.Shifts.Shift
  alias DriversSeatCoop.Util.DateTimeUtil

  require Logger

  @doc """
  Return the id of the most recent unfinished shift, if the user has one not associated to any device
  Otherwise return nil.
  """
  def get_current_shift_id(user_id, nil) do
    from(s in get_current_shifts_for_user_query(user_id),
      select: s.id,
      where: is_nil(s.device_id),
      limit: 1
    )
    |> Repo.one()
  end

  def get_current_shift_id(user_id, device_id) do
    shift =
      from(s in get_current_shifts_for_user_query(user_id),
        select: s.id,
        where: s.device_id == ^device_id,
        limit: 1
      )
      |> Repo.one()

    if is_nil(shift) do
      get_current_shift_id(user_id, nil)
    else
      shift
    end
  end

  def get_users_with_open_shifts do
    from(u in User,
      where: not u.deleted,
      where:
        fragment(
          "EXISTS (SELECT * FROM shifts S where S.user_id = ? AND S.deleted = false AND S.end_time IS NULL)",
          u.id
        )
    )
    |> Repo.all()
  end

  def get_current_shifts_for_user(user_id) do
    get_current_shifts_for_user_query(user_id)
    |> Repo.all()
  end

  def is_user_currently_on_shift(user_id) do
    not Enum.empty?(get_current_shifts_for_user(user_id))
  end

  defp get_current_shifts_for_user_query(user_id) do
    from(s in Shift,
      where: s.user_id == ^user_id,
      where: not s.deleted,
      where: is_nil(s.end_time),
      order_by: [desc: :start_time]
    )
  end

  def query_shifts_for_user(user_id) do
    from(s in Shift,
      where: s.user_id == ^user_id,
      where: not s.deleted
    )
  end

  def list_shifts_by_user_id(user, opts \\ %{}) do
    user_id = user.id

    limit = Map.get(opts, :limit, 10)
    max_id = Map.get(opts, :max_id)
    date = Map.get(opts, :inserted_at_date)
    max_date = Map.get(opts, :max_date)
    since_date = Map.get(opts, :since_date)
    work_date = Map.get(opts, :work_date)
    include_mileage = Map.get(opts, :include_mileage)

    query =
      from(s in query_shifts_for_user(user.id),
        order_by: [desc: :start_time]
      )
      |> query_shifts_limit(limit)
      |> query_shifts_filter_max_id(max_id)
      |> query_shifts_filter_since_max(since_date, max_date)
      |> query_shifts_filter_working_day(user, work_date)
      |> query_shifts_filter_inserted_date(date)

    if include_mileage do
      from(s in query,
        select: %{
          id: s.id,
          end_time: s.end_time,
          frontend_mileage:
            fragment(
              "(SELECT ST_Length(ST_MakeLine(geometry)::geography) * 0.0006214 FROM points P WHERE P.user_id = ? AND P.recorded_at BETWEEN ? and ?)",
              ^user_id,
              s.start_time,
              s.end_time
            ),
          start_time: s.start_time,
          user_id: s.user_id
        }
      )
    else
      from(s in query,
        select: %{
          id: s.id,
          end_time: s.end_time,
          frontend_mileage: s.frontend_mileage,
          start_time: s.start_time,
          user_id: s.user_id
        }
      )
    end
    |> Repo.all()
  end

  def get_shift_date_range(user) do
    [start_time, end_time] =
      from(s in Shift,
        where: s.user_id == ^user.id,
        select: [min(s.start_time), max(s.end_time)]
      )
      |> Repo.one()

    cond do
      is_nil(start_time) ->
        [nil, nil]

      is_nil(end_time) ->
        [
          User.datetime_to_working_day(start_time, user),
          User.datetime_to_working_day(DateTime.utc_now(), user)
        ]

      true ->
        [
          User.datetime_to_working_day(start_time, user),
          User.datetime_to_working_day(end_time, user)
        ]
    end
  end

  def query_shifts_limit(query, nil) do
    query
  end

  def query_shifts_limit(query, limit) do
    from(s in query,
      limit: ^limit
    )
  end

  def query_shifts_filter_max_id(query, nil) do
    query
  end

  def query_shifts_filter_max_id(query, max_id) do
    from(s in query, where: s.id < ^max_id)
  end

  def query_shifts_filter_inserted_date(query, nil) do
    query
  end

  def query_shifts_filter_inserted_date(query, date) do
    from(s in query, where: fragment("?::date = ?", s.inserted_at, ^date))
  end

  def query_shifts_filter_since_max(query, nil, nil) do
    query
  end

  def query_shifts_filter_since_max(query, since_date, nil) do
    since = %NaiveDateTime{
      year: since_date.year,
      month: since_date.month,
      day: since_date.day,
      hour: 4,
      minute: 0,
      second: 0
    }

    from(s in query,
      where: fragment("? >= ? or ? <= ?", s.start_time, ^since, s.end_time, ^since)
    )
  end

  def query_shifts_filter_since_max(query, nil, max_date) do
    tomorrow = Date.add(max_date, 1)

    max = %NaiveDateTime{
      year: tomorrow.year,
      month: tomorrow.month,
      day: tomorrow.day,
      hour: 4,
      minute: 0,
      second: 0
    }

    from(s in query,
      where: fragment("? <= ? or ? <= ?", s.start_time, ^max, s.end_time, ^max)
    )
  end

  def query_shifts_filter_since_max(query, since_date, max_date) do
    since = %NaiveDateTime{
      year: since_date.year,
      month: since_date.month,
      day: since_date.day,
      hour: 4,
      minute: 0,
      second: 0
    }

    tomorrow = Date.add(max_date, 1)

    max = %NaiveDateTime{
      year: tomorrow.year,
      month: tomorrow.month,
      day: tomorrow.day,
      hour: 4,
      minute: 0,
      second: 0
    }

    from(s in query,
      where:
        fragment(
          "(? >= ? and ? <= ?) OR (? >= ? and ? <= ?) OR (? <= ? and ? >= ?)",
          s.start_time,
          ^since,
          s.start_time,
          ^max,
          s.end_time,
          ^since,
          s.end_time,
          ^max,
          s.start_time,
          ^since,
          s.end_time,
          ^max
        )
    )
  end

  def query_shifts_filter_working_day(query, _user, nil) do
    query
  end

  def query_shifts_filter_working_day(query, user, work_date) do
    [work_date_start, work_date_end] = User.working_day_bounds(work_date, user)

    query_shifts_filter_time_range(query, work_date_start, work_date_end)
  end

  def query_shifts_filter_time_range(query, start_time, end_time) do
    from(s in query,
      where:
        fragment(
          "(? BETWEEN ? AND ?) OR (COALESCE(?, now() at time zone 'utc') BETWEEN ? AND ?) OR (? <= ? and COALESCE(?, now() at time zone 'utc') >= ?)",
          s.start_time,
          ^start_time,
          ^end_time,
          s.end_time,
          ^start_time,
          ^end_time,
          s.start_time,
          ^start_time,
          s.end_time,
          ^end_time
        )
    )
  end

  def create_shift(attrs, user_id, nil) do
    shift =
      from(s in get_current_shifts_for_user_query(user_id),
        where: is_nil(s.device_id),
        limit: 1
      )
      |> Repo.one()

    if is_nil(shift) do
      %Shift{user_id: user_id, device_id: nil}
      |> Shift.changeset(attrs)
      |> Repo.insert()
    else
      {:ok, shift}
    end
  end

  def create_shift(attrs, user_id, device_id) do
    shift =
      from(s in get_current_shifts_for_user_query(user_id),
        where: s.device_id == ^device_id,
        limit: 1
      )
      |> Repo.one()

    if is_nil(shift) do
      %Shift{user_id: user_id, device_id: device_id}
      |> Shift.changeset(attrs)
      |> Repo.insert()
    else
      {:ok, shift}
    end
  end

  @doc """
  Gets a single shift.

  Raises `Ecto.NoResultsError` if the Shift does not exist.

  ## Examples

      iex> get_shift!(123)
      %Shift{}

      iex> get_shift!(456)
      ** (Ecto.NoResultsError)

  """
  def get_shift!(id), do: Repo.get!(Shift, id)

  @doc """
  Updates a shift.

  ## Examples

      iex> update_shift(shift, %{field: new_value})
      {:ok, %Shift{}}

      iex> update_shift(shift, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_shift(%Shift{} = shift, attrs) do
    shift
    |> Shift.changeset(attrs)
    |> Repo.update()
  end

  def update_working_times(user, work_date, new_shifts) do
    timezone = Activities.identify_timezone_for_user_work_date(user, work_date)
    [work_day_start, work_day_end] = DateTimeUtil.working_day_bounds(work_date, timezone)

    # get any shifts that occur on the work date
    old_shift_qry =
      query_shifts_for_user(user.id)
      |> query_shifts_filter_time_range(work_day_start, work_day_end)

    # find the earliest start and latest end date for shifts in question
    [earliest_start, latest_end] =
      old_shift_qry
      |> select([s], [min(s.start_time), max(s.end_time)])
      |> Repo.one()

    # create transaction
    multi = Ecto.Multi.new()

    # mark old shifts as deleted
    multi =
      multi
      |> Ecto.Multi.update_all(
        :delete_shifts,
        old_shift_qry,
        set: [deleted: true]
      )

    # if there is a shift that started before the work day, update it so that
    # it at ends at the sart of the prior workday
    multi =
      if is_nil(earliest_start) or DateTime.compare(earliest_start, work_day_start) in [:eq, :gt] do
        multi
      else
        changeset =
          Shift.changeset(%Shift{user_id: user.id}, %{
            start_time: earliest_start,
            end_time: work_day_start
          })

        Ecto.Multi.insert(multi, "From Before Workday", changeset)
      end

    # if there is a shift that ends after the work day, update it so that
    # it at starts ends at the sart of the next workday
    multi =
      if is_nil(latest_end) or DateTime.compare(latest_end, work_day_end) in [:eq, :lt] do
        multi
      else
        changeset =
          Shift.changeset(%Shift{user_id: user.id}, %{
            start_time: work_day_end,
            end_time: latest_end
          })

        Ecto.Multi.insert(multi, "From After Workday", changeset)
      end

    # Add the updated shifts
    multi =
      if Enum.empty?(new_shifts) do
        multi
      else
        [multi, _] =
          Enum.reduce(new_shifts, [multi, 0], fn shift, [m, idx] ->
            changeset = Shift.changeset(%Shift{user_id: user.id}, shift)
            [Ecto.Multi.insert(m, "New Shift #{idx}", changeset), idx + 1]
          end)

        multi
      end

    Repo.transaction(multi)
  end
end
