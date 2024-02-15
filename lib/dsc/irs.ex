defmodule DriversSeatCoop.Irs do
  @spec irs_cents_per_mile_by_date(DateTime.t()) :: Decimal.t()
  defp irs_cents_per_mile_by_date(%DateTime{year: 2022, month: month}) do
    # IRS issued multiple rates for the year 2022
    if month >= 7 do
      # rate for 2022-07-01 until the end of the year
      Decimal.new("62.5")
    else
      # rate for the beginning of the year until 2022-06-30
      Decimal.new("58.5")
    end
  end

  defp irs_cents_per_mile_by_date(%DateTime{year: 2024}), do: Decimal.new(67)
  defp irs_cents_per_mile_by_date(%DateTime{year: 2023}), do: Decimal.new("65.5")
  defp irs_cents_per_mile_by_date(%DateTime{year: 2021}), do: Decimal.new(56)
  defp irs_cents_per_mile_by_date(%DateTime{year: 2020}), do: Decimal.new("57.5")
  defp irs_cents_per_mile_by_date(%DateTime{year: 2019}), do: Decimal.new(58)
  defp irs_cents_per_mile_by_date(%DateTime{year: 2018}), do: Decimal.new("54.5")
  defp irs_cents_per_mile_by_date(%DateTime{year: 2017}), do: Decimal.new("53.5")
  defp irs_cents_per_mile_by_date(%DateTime{year: 2016}), do: Decimal.new(54)
  defp irs_cents_per_mile_by_date(%DateTime{year: 2015}), do: Decimal.new("57.5")
  defp irs_cents_per_mile_by_date(%DateTime{year: 2014}), do: Decimal.new(56)
  defp irs_cents_per_mile_by_date(%DateTime{year: 2013}), do: Decimal.new("56.5")
  defp irs_cents_per_mile_by_date(%DateTime{year: 2012}), do: Decimal.new("55.5")
  defp irs_cents_per_mile_by_date(_), do: Decimal.new(0)

  def current_deduction_rate, do: irs_cents_per_mile_by_date(DateTime.utc_now())

  @spec calculate_irs_expense(DateTime.t(), float()) :: integer
  def calculate_irs_expense(%DateTime{} = datetime, miles) when is_float(miles) do
    calculate_irs_expense(datetime, Decimal.from_float(miles))
  end

  @spec calculate_irs_expense(DateTime.t(), Decimal.t()) :: integer
  def calculate_irs_expense(_date_or_time, nil) do
    nil
  end

  def calculate_irs_expense(%DateTime{} = datetime, miles) do
    irs_rate = irs_cents_per_mile_by_date(datetime)

    Decimal.mult(miles, irs_rate)
    |> Decimal.round()
    |> Decimal.to_integer()
  end

  def calculate_irs_expense(%Date{} = date, miles),
    do: calculate_irs_expense(DateTime.new!(date, ~T[00:00:00]), miles)
end
