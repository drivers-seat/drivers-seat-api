defmodule DriversSeatCoop.Repo.Migrations.RemoveMetroAreaFromApiDb do
  use Ecto.Migration

  def change do
    execute("ALTER TABLE public.users DROP CONSTRAINT IF EXISTS users_metro_area_id_fkey")
    execute("ALTER TABLE public.users DROP COLUMN IF EXISTS metro_area_id")
    execute("DROP TABLE IF EXISTS public.metro_areas")
  end
end
