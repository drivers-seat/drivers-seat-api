defmodule DriversSeatCoop.IrsTest do
  alias DriversSeatCoop.Irs
  use DriversSeatCoop.DataCase

  describe "irs" do
    test "calculate_irs_expense accepts decimal miles" do
      assert Irs.calculate_irs_expense(~U[2023-01-01 01:01:01Z], Decimal.new("50.5")) == 3308
      assert Irs.calculate_irs_expense(~U[2022-07-01 01:01:01Z], Decimal.new("50.5")) == 3156
      assert Irs.calculate_irs_expense(~U[2022-01-01 01:01:01Z], Decimal.new("50.5")) == 2954
      assert Irs.calculate_irs_expense(~U[2021-01-01 01:01:01Z], Decimal.new("50.5")) == 2828
      assert Irs.calculate_irs_expense(~U[2020-01-01 01:01:01Z], Decimal.new("50.5")) == 2904
      assert Irs.calculate_irs_expense(~U[2019-01-01 01:01:01Z], Decimal.new("50.5")) == 2929
      assert Irs.calculate_irs_expense(~U[2018-01-01 01:01:01Z], Decimal.new("50.5")) == 2752
      assert Irs.calculate_irs_expense(~U[2017-01-01 01:01:01Z], Decimal.new("50.5")) == 2702
      assert Irs.calculate_irs_expense(~U[2016-01-01 01:01:01Z], Decimal.new("50.5")) == 2727
      assert Irs.calculate_irs_expense(~U[2015-01-01 01:01:01Z], Decimal.new("50.5")) == 2904
      assert Irs.calculate_irs_expense(~U[2014-01-01 01:01:01Z], Decimal.new("50.5")) == 2828
      assert Irs.calculate_irs_expense(~U[2013-01-01 01:01:01Z], Decimal.new("50.5")) == 2853
      assert Irs.calculate_irs_expense(~U[2012-01-01 01:01:01Z], Decimal.new("50.5")) == 2803

      # unknown years return zero
      assert Irs.calculate_irs_expense(~U[1000-01-01 01:01:01Z], Decimal.new("50.5")) == 0
    end
  end

  test "calculate_irs_expense accepts float miles" do
    assert Irs.calculate_irs_expense(~U[2023-01-01 01:01:01Z], 50.5) == 3308
    assert Irs.calculate_irs_expense(~U[2022-07-01 01:01:01Z], 50.5) == 3156
    assert Irs.calculate_irs_expense(~U[2022-01-01 01:01:01Z], 50.5) == 2954
    assert Irs.calculate_irs_expense(~U[2021-01-01 01:01:01Z], 50.5) == 2828
    assert Irs.calculate_irs_expense(~U[2020-01-01 01:01:01Z], 50.5) == 2904
    assert Irs.calculate_irs_expense(~U[2019-01-01 01:01:01Z], 50.5) == 2929
    assert Irs.calculate_irs_expense(~U[2018-01-01 01:01:01Z], 50.5) == 2752
    assert Irs.calculate_irs_expense(~U[2017-01-01 01:01:01Z], 50.5) == 2702
    assert Irs.calculate_irs_expense(~U[2016-01-01 01:01:01Z], 50.5) == 2727
    assert Irs.calculate_irs_expense(~U[2015-01-01 01:01:01Z], 50.5) == 2904
    assert Irs.calculate_irs_expense(~U[2014-01-01 01:01:01Z], 50.5) == 2828
    assert Irs.calculate_irs_expense(~U[2013-01-01 01:01:01Z], 50.5) == 2853
    assert Irs.calculate_irs_expense(~U[2012-01-01 01:01:01Z], 50.5) == 2803

    # unknown years return zero
    assert Irs.calculate_irs_expense(~U[1000-01-01 01:01:01Z], 50.5) == 0
  end
end
