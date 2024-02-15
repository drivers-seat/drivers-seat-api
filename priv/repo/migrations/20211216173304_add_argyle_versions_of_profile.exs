defmodule DriversSeatCoop.Repo.Migrations.AddArgyleVersionsOfProfile do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:country_argyle, :text)
      add(:gender_argyle, :text)
      add(:postal_code_argyle, :text)
      add(:vehicle_make_argyle, :text)
      add(:vehicle_model_argyle, :text)
      add(:vehicle_year_argyle, :integer)
    end
  end
end
