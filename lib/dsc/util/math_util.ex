defmodule DriversSeatCoop.Util.MathUtil do
  @moduledoc """
  This module contains helper functions for performing simple math functions.
  Generally handles null cases
  """

  def round(nil, _places) do
    nil
  end

  def round(value, places) when is_float(value) do
    Float.round(value, places)
  end

  def round(value, _places) when is_integer(value) do
    value
  end

  def round(%Decimal{} = value, places) do
    Decimal.round(value, places)
  end

  def subtract(nil, nil) do
    nil
  end

  def subtract(nil, %Decimal{} = b) do
    Decimal.mult(b, -1)
  end

  def subtract(nil, b) do
    -b
  end

  def subtract(a, nil) do
    a
  end

  def subtract(%Decimal{} = a, b) do
    Decimal.sub(a, b)
  end

  def subtract(a, b) do
    a - b
  end

  def mult(nil, _b) do
    nil
  end

  def mult(_a, nil) do
    nil
  end

  def mult(a, %Decimal{} = b) when is_integer(a) do
    Decimal.mult(b, a)
  end
end
