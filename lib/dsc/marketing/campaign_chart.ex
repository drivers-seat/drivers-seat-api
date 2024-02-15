defmodule DriversSeatCoop.Marketing.CampaignChart do
  def new(chart_type) when chart_type in [:bar, :line, :pie, :doughnut, :scatter, :radar] do
    %{
      type: :chart,
      chart_type: chart_type,
      chart_height: "300px",
      chart_options: %{
        responsive: true,
        maintainAspectRatio: false,
        scales: %{
          x: %{
            grid: %{
              display: false
            }
          }
        }
      }
    }
  end

  def with_dataset(%{type: :chart} = chart, dataset_or_datasets) do
    dataset_or_datasets = List.wrap(dataset_or_datasets)
    data_node = Map.get(chart, :chart_data) || %{}

    data_node =
      Map.put(data_node, :datasets, (Map.get(data_node, :datasets) || []) ++ dataset_or_datasets)

    Map.put(chart, :chart_data, data_node)
  end

  def with_label(%{type: :chart} = chart, label_or_labels) do
    label_or_labels = List.wrap(label_or_labels)
    data_node = Map.get(chart, :chart_data) || %{}

    data_node =
      Map.put(data_node, :labels, (Map.get(data_node, :labels) || []) ++ label_or_labels)

    Map.put(chart, :chart_data, data_node)
  end

  def with_options(%{type: :chart} = chart, %{} = options),
    do: Map.put(chart, :chart_options, options)

  def with_option(%{type: :chart} = chart, option, option_value)
      when is_atom(option) do
    options_node =
      (Map.get(chart, :chart_options) || %{})
      |> Map.put(option, option_value)

    Map.put(chart, :chart_options, options_node)
  end

  def with_tooltip_options(%{type: :chart} = chart, %{} = options),
    do: Map.put(chart, :tooltip_options, options)

  def with_tooltip_option(%{type: :chart} = chart, option, option_value)
      when is_atom(option) do
    options_node =
      (Map.get(chart, :tooltip_options) || %{})
      |> Map.put(option, option_value)

    Map.put(chart, :tooltip_options, options_node)
  end

  def with_legend_options(%{type: :chart} = chart, %{} = options),
    do: Map.put(chart, :legend_options, options)

  def with_legend_option(%{type: :chart} = chart, option, option_value)
      when is_atom(option) do
    options_node =
      (Map.get(chart, :legend_options) || %{})
      |> Map.put(option, option_value)

    Map.put(chart, :legend_options, options_node)
  end

  def with_add_on(%{type: :chart} = chart, add_on, settings \\ nil)
      when is_atom(add_on) do
    add_ons = Map.get(chart, :add_ons) || %{}

    add_ons =
      cond do
        is_nil(settings) ->
          Map.put(add_ons, add_on, nil)

        Keyword.keyword?(settings) ->
          settings_map =
            Enum.reduce(settings, %{}, fn {k, v}, result -> Map.put(result, k, v) end)

          Map.put(add_ons, add_on, settings_map)

        true ->
          Map.put(add_ons, add_on, settings)
      end

    Map.put(chart, :add_ons, add_ons)
  end

  def with_height(%{type: :chart} = chart, height_pixels),
    do: Map.put(chart, :chart_height, "#{height_pixels}px")

  def with_chart_title(%{type: :chart} = chart, title_or_titles, options \\ nil) do
    options_node = Map.get(chart, :chart_options) || %{}
    plugins_node = Map.get(options_node, :plugins) || %{}
    title_settings = Map.get(plugins_node, :title) || %{}

    text = List.wrap(Map.get(title_settings, :text)) ++ List.wrap(title_or_titles)

    title_settings =
      title_settings
      |> Map.put(:text, text)
      |> Map.put(:display, true)

    title_settings =
      if is_nil(options) do
        title_settings
      else
        options
        |> Keyword.to_list()
        |> Enum.reduce(title_settings, fn {k, v}, x ->
          Map.put(x, k, v)
        end)
      end

    plugins_node = Map.put(plugins_node, :title, title_settings)
    options_node = Map.put(options_node, :plugins, plugins_node)
    Map.put(chart, :chart_options, options_node)
  end

  def with_scale_range(%{type: :chart} = chart, scale, min_value \\ nil, max_value \\ nil)
      when is_atom(scale) do
    options_node = Map.get(chart, :chart_options) || %{}
    scales_node = Map.get(options_node, :scales) || %{}

    scale_node =
      Map.get(scales_node, scale) ||
        %{}
        |> Map.put(:min, min_value)
        |> Map.put(:max, max_value)

    scales_node = Map.put(scales_node, scale, scale_node)
    options_node = Map.put(options_node, :scales, scales_node)

    Map.put(chart, :chart_options, options_node)
  end
end
