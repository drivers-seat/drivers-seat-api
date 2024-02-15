defmodule DriversSeatCoop.Repo.Migrations.AddSelectedMileageToTimespan do
  use Ecto.Migration

  def change do
    alter table(:timespans) do
      add(:selected_miles, :decimal, null: true)
      add(:selected_miles_engaged, :decimal, null: true)
      add(:selected_miles_deduction_cents, :integer, null: true)
      add(:selected_miles_deduction_cents_engaged, :integer, null: true)
      add(:selected_miles_quality_percent, :decimal, null: true)
    end
  end
end
