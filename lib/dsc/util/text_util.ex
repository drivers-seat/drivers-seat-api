defmodule DriversSeatCoop.Util.TextUtil do
  @moduledoc """
  This module contains helper functions for working with text
  """

  @doc """
  Replace a value in a map based on a function applied against an existing value.
  """
  def friendly_csv_list(items, last_item_text) do
    items =
      List.wrap(items)
      |> Enum.map(fn i -> "#{i}" end)
      |> Enum.uniq()

    if Enum.count(items) < 2 do
      Enum.at(items, 0)
    else
      part_1 =
        items
        |> Enum.drop(-1)
        |> Enum.join(", ")

      "#{part_1} #{last_item_text} #{Enum.at(items, -1)}"
    end
  end

  def single_or_plural(items, single_label, plural_label) do
    items =
      List.wrap(items)
      |> Enum.uniq()

    if Enum.count(items) < 2, do: single_label, else: plural_label
  end
end
