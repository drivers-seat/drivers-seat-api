defmodule DriversSeatCoop.Repo.Migrations.AddIndexesForDeviceId do
  use Ecto.Migration

  @doc """
  Support the delete of devices.  These indexes will assist in the FK check
  when trying to delete a user's device during purge
  """
  def change do
    execute("CREATE INDEX IF NOT EXISTS points_device_id ON points(device_id)")
    execute("CREATE INDEX IF NOT EXISTS shifts_device_id ON shifts(device_id)")
  end
end
