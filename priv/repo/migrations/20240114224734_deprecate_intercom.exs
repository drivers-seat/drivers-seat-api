defmodule DriversSeatCoop.Repo.Migrations.DeprecateIntercom do
  use Ecto.Migration

  def change do
    execute "DELETE FROM user_service_identifiers WHERE service = 'intercom'"
  end
end
