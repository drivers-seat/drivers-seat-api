defmodule DriversSeatCoop.Earnings.TimespanCalcMethod do
  use EctoEnum,
    type: :timespan_calc_method,
    enums: [
      :user_facing
      # :auto_calculated,
    ]
end
