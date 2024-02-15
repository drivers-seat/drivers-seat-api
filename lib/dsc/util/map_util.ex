defmodule DriversSeatCoop.Util.MapUtil do
  @moduledoc """
  This module contains helper functions for working with maps
  """

  @doc """
  Replace a value in a map based on a function applied against an existing value.
  """
  def replace(map, prop, fx) when is_map(map) and is_atom(prop) and is_function(fx) do
    case Map.fetch(map, prop) do
      {:ok, val} ->
        Map.put(map, prop, fx.(val))

      _ ->
        map
    end
  end

  def get_value_or_default(nil = _map, _key, default) do
    default
  end

  def get_value_or_default(map, key, default) do
    Map.get(map, key) || default
  end
end
