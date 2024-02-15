defmodule DriversSeatCoop.Repo.Migrations.AddDateTruncFunctionToPostgres do
  use Ecto.Migration

  def change do
    execute("
    CREATE OR REPLACE FUNCTION public.date_bin (
      stride INTERVAL,
      source_ts TIMESTAMPTZ,
      base_ts TIMESTAMPTZ)
    RETURNS TIMESTAMPTZ
    LANGUAGE SQL
    IMMUTABLE
    AS $$
    SELECT
      base_ts
      + FLOOR(EXTRACT(epoch FROM source_ts - base_ts) / EXTRACT(epoch FROM stride))::BIGINT
      * stride;
    $$;
    ")
  end
end
