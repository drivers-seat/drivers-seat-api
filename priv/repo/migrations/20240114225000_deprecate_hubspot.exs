defmodule DriversSeatCoop.Repo.Migrations.DeprecateHubspot do
  use Ecto.Migration

  def change do
    execute "DELETE FROM user_service_identifiers WHERE service = 'hubspot'"
  end
end
