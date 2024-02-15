defmodule DriversSeatCoop.Regions do
  import Ecto.Query, warn: false
  import Geo.PostGIS, warn: false
  import Ecto.Adapters.SQL, warn: false

  require Logger

  alias DriversSeatCoop.Accounts.User
  alias DriversSeatCoop.Regions.County
  alias DriversSeatCoop.Regions.MetroArea
  alias DriversSeatCoop.Regions.PostalCode
  alias DriversSeatCoop.Regions.State
  alias DriversSeatCoop.Repo

  def get_state_by_id(nil = _id), do: nil

  def get_state_by_id(id) do
    query_states()
    |> where([st], st.id == ^id)
    |> Repo.one()
  end

  def query_states, do: from(state in State)

  def get_county_by_id(nil = _id), do: nil

  def get_county_by_id(id) do
    query_counties()
    |> where([st], st.id == ^id)
    |> Repo.one()
  end

  def query_counties, do: from(county in County)

  def get_postal_code(nil, _include_metro_area), do: nil

  def get_postal_code(postal_code, include_metro_area) do
    qry =
      from(postal_code in PostalCode,
        where: postal_code.postal_code == ^postal_code,
        limit: 1
      )

    qry =
      if include_metro_area do
        from(postal_code in qry,
          preload: [:metro_area]
        )
      else
        qry
      end

    Repo.all(qry)
    |> Enum.at(0)
  end

  def get_metro_area_by_id(nil), do: nil

  def get_metro_area_by_id(id) do
    query_metro_areas()
    |> where([metro], metro.id == ^id)
    |> Repo.one()
  end

  def get_metro_area_id_for_point(nil = _point), do: nil

  def get_metro_area_id_for_point(%Geo.Point{} = point) do
    query_metro_areas()
    |> query_metro_area_contains_point(point)
    |> select([m], m.id)
    |> limit(1)
    |> Repo.one()
  end

  def get_metro_areas do
    query_metro_areas()
    |> Repo.all()
  end

  def get_metro_area_ids do
    query_metro_areas()
    |> select([m], m.id)
    |> Repo.all()
  end

  def query_metro_areas, do: from(metro in MetroArea)
  def query_metro_areas_hourly_pay_stat_coverage_percent(qry, nil, nil), do: qry

  def query_metro_areas_hourly_pay_stat_coverage_percent(qry, nil, max),
    do: where(qry, [metro], metro.hourly_pay_stat_coverage_percent <= ^max)

  def query_metro_areas_hourly_pay_stat_coverage_percent(qry, min, nil),
    do: where(qry, [metro], metro.hourly_pay_stat_coverage_percent >= ^min)

  def query_metro_areas_hourly_pay_stat_coverage_percent(qry, min, max) do
    qry
    |> query_metro_areas_hourly_pay_stat_coverage_percent(min, nil)
    |> query_metro_areas_hourly_pay_stat_coverage_percent(nil, max)
  end

  def get_metro_area_for_user(%User{} = user),
    do: get_metro_area_by_postal_code([user.postal_code, user.postal_code_argyle])

  def get_metro_area_by_postal_code(postal_code_or_codes) do
    List.wrap(postal_code_or_codes)
    |> Enum.filter(fn pc -> not is_nil(pc) end)
    |> Enum.reduce(nil, fn pc, result ->
      if is_nil(result),
        do: Map.get(get_postal_code(pc, true) || %{}, :metro_area),
        else: result
    end)
  end

  def query_metro_area_contains_point(qry, %Geo.Point{} = point),
    do: where(qry, [m], st_within(^point, m.geometry))
end
