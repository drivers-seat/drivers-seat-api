defmodule DriversSeatCoop.Repo.Migrations.AddReferralTypeHourlyPayAnalytics do
  use Ecto.Migration

  def change do
    execute("ALTER TYPE referral_type ADD VALUE IF NOT EXISTS 'app_invite_hourly_pay_analytics'")
  end
end
