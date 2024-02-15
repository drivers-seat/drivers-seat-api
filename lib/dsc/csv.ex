defmodule DriversSeatCoop.CSV do
  @moduledoc """
  This module contains helper functions for exporting data in a CSV format.
  """
  alias NimbleCSV.RFC4180, as: CSV

  defp extract_fields_in_order(map, columns) do
    columns
    |> Enum.map(&Map.get(map, &1))
  end

  defp maps_to_csv_rows(collection, columns) do
    collection
    |> Stream.map(fn row ->
      extract_fields_in_order(row, columns)
    end)
  end

  def build_csv_stream(collection, columns, options \\ []) do
    replace_underscore = Keyword.get(options, :replace_underscores, false)

    header = Enum.map(columns, &Atom.to_string/1)

    header =
      if replace_underscore do
        Enum.map(header, fn h -> String.replace(h, "_", " ") end)
      else
        header
      end

    content = maps_to_csv_rows(collection, columns)

    Stream.concat([header], content)
    |> CSV.dump_to_stream()
  end
end
