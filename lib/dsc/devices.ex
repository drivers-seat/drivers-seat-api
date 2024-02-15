defmodule DriversSeatCoop.Devices do
  import Ecto.Query, warn: false
  alias DriversSeatCoop.Accounts
  alias DriversSeatCoop.Devices.Device
  alias DriversSeatCoop.Repo

  @doc """
    Get's an existing device for a user using reported device id
  """
  def get_for_user_by_device_id(user_id, device_id) do
    Repo.get_by(Device, user_id: user_id, device_id: device_id)
  end

  @doc """
    Get's an existing device for a user and updates as necessary
    If not exists, creates a new one for that user
  """
  def get_or_update!(user_id, device_id, attrs, update_access_date \\ true) do
    device = get_for_user_by_device_id(user_id, device_id)

    device =
      if is_nil(device) do
        %Device{
          user_id: user_id,
          device_id: device_id
        }
      else
        device
      end

    Device.changeset(device, attrs, update_access_date)
    |> Repo.insert_or_update!()
  end

  def query do
    from(device in Device)
  end

  def query_filter_user(query, user_id_or_ids) do
    user_id_or_ids = List.wrap(user_id_or_ids)

    query
    |> where([d], d.user_id in ^user_id_or_ids)
  end

  def query_filter_app_version(query, app_version_or_versions, include \\ true) do
    app_version_or_versions = List.wrap(app_version_or_versions)

    if include do
      where(query, [d], d.app_version in ^app_version_or_versions)
    else
      where(query, [d], d.app_version not in ^app_version_or_versions)
    end
  end

  def query_filter_device_id(query, device_id_or_ids, include \\ true) do
    device_id_or_ids = List.wrap(device_id_or_ids)

    if include do
      where(query, [d], d.device_id in ^device_id_or_ids)
    else
      where(query, [d], d.device_id not in ^device_id_or_ids)
    end
  end

  def prod_devices_qry do
    # get a list of non-prod/test users
    non_prod_users_qry =
      Accounts.get_users_query()
      |> Accounts.filter_non_prod_users_query(true)
      |> select([u], u.id)

    # get non prod users' devices
    non_prod_devices_qry =
      query()
      |> where([d], d.user_id in subquery(non_prod_users_qry))

    # user the ids to filter out these devices from the prod users list
    non_prod_device_ids_qry =
      non_prod_devices_qry
      |> select([d], d.device_id)

    query()
    |> where([d], d.device_id not in subquery(non_prod_device_ids_qry))
    |> union_all(^non_prod_devices_qry)
  end

  def get_versions_greater_than_or_equal(version) do
    version = Device.get_clean_version(version)

    version_requirement = ">= #{version}"

    query()
    |> where([d], not is_nil(d.app_version))
    |> group_by([d], [d.app_version])
    |> select([d], d.app_version)
    |> Repo.all()
    |> Enum.filter(fn v -> Device.is_version_match?(v, version_requirement) end)
  end

  def get_user_ids_on_version_or_greater_query(version) do
    versions = get_versions_greater_than_or_equal(version)

    from(d in subquery(prod_devices_qry()))
    |> query_filter_app_version(versions, true)
    |> select([d], d.user_id)
    |> group_by([d], d.user_id)
  end
end
