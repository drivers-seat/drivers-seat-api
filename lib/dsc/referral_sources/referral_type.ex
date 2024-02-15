defmodule DriversSeatCoop.ReferralType do
  use EctoEnum,
    type: :referral_type,
    enums: [:app_invite_hourly_pay_analytics, :app_invite_menu, :marketing_materials]
end
