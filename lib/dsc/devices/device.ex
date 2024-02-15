defmodule DriversSeatCoop.Devices.Device do
  use Ecto.Schema
  import Ecto.Changeset

  @required_fields ~w(
    device_id
    user_id
  )a

  # NOTE: role is set through a separate changeset to prevent normal requests
  # from changing it.
  @optional_fields ~w(
    device_language
    device_platform
    app_version
    device_os
    device_name
    location_tracking_config_status
    last_access_date
  )a

  schema "devices" do
    field :device_id, :string
    field :app_version, :string
    field :device_os, :string
    field :device_language, :string
    field :device_platform, :string
    field :device_name, :string
    field :location_tracking_config_status, :string
    field :last_access_date, :date

    belongs_to :user, DriversSeatCoop.Accounts.User

    timestamps()
  end

  @doc false
  def changeset(device, attrs, update_last_access_date \\ true) do
    changeset =
      device
      |> cast(attrs, @required_fields ++ @optional_fields)
      |> validate_required(@required_fields)
      |> unique_constraint([:user_id, :device_id], name: :devices_user_device_id_key)

    if update_last_access_date do
      cast(changeset, %{last_access_date: Date.utc_today()}, [
        :last_access_date
      ])
    else
      changeset
    end
  end

  @doc """
  Sometimes device versions have extra info in them
  Chop off anything after the 3rd token and ensure that there are 3 tokens
  For exmaple, 3.0.2.778 (xyz) = 3.0.2
  """
  def get_clean_version(version) do
    tokens =
      String.split(version || "", ".", trim: true)
      |> Enum.flat_map(fn t -> String.split(String.trim(t), " ") end)

    "#{Enum.at(tokens, 0, "0")}.#{Enum.at(tokens, 1, "0")}.#{Enum.at(tokens, 2, "0")}"
  end

  def compare_version(%DriversSeatCoop.Devices.Device{} = device, to_version) do
    compare_version(device.app_version, to_version)
  end

  def compare_version(version, to_version) do
    version = get_clean_version(version)
    to_version = get_clean_version(to_version)

    Version.compare(version, to_version)
  end

  def is_version_match?(nil = _device, _version_requirement) do
    false
  end

  def is_version_match?(%DriversSeatCoop.Devices.Device{} = device, version_requirement) do
    is_version_match?(device.app_version, version_requirement)
  end

  def is_version_match?(version, version_requirement) do
    version = get_clean_version(version)
    Version.match?(version, version_requirement)
  end
end
