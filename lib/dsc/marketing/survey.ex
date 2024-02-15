defmodule DriversSeatCoop.Marketing.Survey do
  alias DriversSeatCoop.Marketing.CampaignHelpers
  alias DriversSeatCoop.Marketing.CampaignState

  def new(id) when is_atom(id) do
    CampaignHelpers.new_campaign(id, :survey)
    |> Map.put(:get_sections, fn %CampaignState{} -> [] end)
  end

  def with_section(survey, fx_or_sections),
    do: CampaignHelpers.wrap_function_returns_array(survey, :get_sections, fx_or_sections)

  def with_conditional_section(obj, conditional_fx, section_or_sections)
      when is_function(conditional_fx) do
    CampaignHelpers.wrap_function_returns_array(obj, :get_sections, fn %CampaignState{} = state ->
      if conditional_fx.(state), do: section_or_sections, else: nil
    end)
  end

  def with_display_class(survey, class_or_classes),
    do: CampaignHelpers.with_display_class(survey, class_or_classes)

  def get_config(
        %{
          type: :survey
        } = campaign,
        %CampaignState{} = state
      ) do
    %{
      sections:
        campaign.get_sections.(state)
        |> Enum.map(fn section ->
          section
          |> Map.take([
            :id,
            :description,
            :title,
            :description,
            :dependencies,
            :validations,
            :pagination,
            :display_class
          ])
          |> Map.put(:actions, section.get_actions.(state))
          |> Map.put(:items, section.get_items.(state))
          |> Map.put(:content_url, section.get_content_url.(state))
        end)
    }
  end
end

defmodule DriversSeatCoop.Marketing.SurveySection do
  alias DriversSeatCoop.Marketing.CampaignHelpers
  alias DriversSeatCoop.Marketing.CampaignState

  def new(id) when is_atom(id) do
    %{
      id: id,
      description: nil,
      title: nil,
      display_class: nil,
      get_items: fn %CampaignState{} -> [] end,
      get_actions: fn %CampaignState{} -> [] end,
      dependencies: %{},
      validations: %{},
      hide_page_markers: false,
      hide_page_navigation: false,
      get_content_url: fn %CampaignState{} -> nil end
    }
  end

  def with_title(section, value_or_values),
    do: Map.put(section, :title, List.wrap(section.title) ++ List.wrap(value_or_values))

  def with_description(section, value_or_values),
    do:
      Map.put(section, :description, List.wrap(section.description) ++ List.wrap(value_or_values))

  def with_display_class(section, class_or_classes),
    do: CampaignHelpers.with_display_class(section, class_or_classes)

  def validate_min_value(section, field, value) when is_atom(field) do
    vlds = Map.get(section, :validations) || %{}

    field_vlds =
      (Map.get(vlds, field) || %{})
      |> Map.put(:min_value, value)

    vlds = Map.put(vlds, field, field_vlds)
    Map.put(section, :validations, vlds)
  end

  def validate_max_value(section, field, value) when is_atom(field) do
    vlds = Map.get(section, :validations) || %{}

    field_vlds =
      Map.get(vlds, field) ||
        %{}
        |> Map.put(:max_value, value)

    vlds = Map.put(vlds, field, field_vlds)
    Map.put(section, :validations, vlds)
  end

  def validate_required(section, field, is_required \\ true) when is_atom(field) do
    vlds = Map.get(section, :validations) || %{}

    field_vlds =
      Map.get(vlds, field) ||
        %{}
        |> Map.put(:required, is_required)

    vlds = Map.put(vlds, field, field_vlds)
    Map.put(section, :validations, vlds)
  end

  def validate_reg_ex(section, field, reg_ex) when is_atom(field) do
    vlds = Map.get(section, :validations) || %{}

    field_vlds =
      Map.get(vlds, field) ||
        %{}
        |> Map.put(:reg_ex, reg_ex)

    vlds = Map.put(vlds, field, field_vlds)
    Map.put(section, :validations, vlds)
  end

  def with_action(section, fx_or_actions),
    do: CampaignHelpers.wrap_function_returns_array(section, :get_actions, fx_or_actions)

  def with_conditional_action(section, conditional_fx, action_or_actions)
      when is_function(conditional_fx),
      do: CampaignHelpers.with_conditional_action(section, conditional_fx, action_or_actions)

  def with_item(section, fx_or_items),
    do: CampaignHelpers.wrap_function_returns_array(section, :get_items, fx_or_items)

  def with_conditional_item(section, conditional_fx, fx_item)
      when is_function(conditional_fx) and is_function(fx_item) do
    CampaignHelpers.wrap_function_returns_array(section, :get_items, fn %CampaignState{} = state ->
      if conditional_fx.(state), do: fx_item.(state), else: nil
    end)
  end

  def with_conditional_item(section, conditional_fx, item_or_items)
      when is_function(conditional_fx) do
    CampaignHelpers.wrap_function_returns_array(section, :get_items, fn %CampaignState{} = state ->
      if conditional_fx.(state), do: item_or_items, else: nil
    end)
  end

  def with_content_url(cta, fx_or_value),
    do: CampaignHelpers.set_content_url_function(cta, :get_content_url, fx_or_value)

  def hide_page_markers(section, hide \\ true) do
    pagination =
      (Map.get(section, :pagination) || %{})
      |> Map.put(:hide_markers, hide)

    Map.put(section, :pagination, pagination)
  end

  def hide_page_navigation(section, hide \\ true) do
    pagination =
      (Map.get(section, :pagination) || %{})
      |> Map.put(:hide_navigation, hide)

    Map.put(section, :pagination, pagination)
  end

  def depends_on_value(section, field, value_or_values, include_or_exclude \\ true)
      when is_atom(field) and is_boolean(include_or_exclude),
      do: CampaignHelpers.depends_on_value(section, field, value_or_values, include_or_exclude)
end

defmodule DriversSeatCoop.Marketing.SurveyItem do
  alias DriversSeatCoop.Marketing.CampaignAction
  alias DriversSeatCoop.Marketing.CampaignHelpers

  defp base(type)
       when type in [
              :info,
              :short_text,
              :long_text,
              :boolean,
              :option,
              :numeric,
              :date,
              :segment_options,
              :action,
              :chart
            ] do
    %{
      type: type,
      display_class: nil
    }
  end

  defp field(id, type)
       when is_atom(id) and
              type in [
                :short_text,
                :long_text,
                :boolean,
                :option,
                :numeric,
                :date,
                :segment_options,
                :chart
              ] do
    base(type)
    |> Map.put(:field, id)
  end

  def text(id, type \\ :short_text)
      when is_atom(id) and type in [:short_text, :long_text] do
    field(id, type)
  end

  def numeric(id) do
    field(id, :numeric)
  end

  def currency(id) do
    numeric(id)
    |> with_uom_left("$")
    |> with_scale(2)
  end

  def with_uom_left(%{} = field, uom), do: Map.put(field, :uom_left, uom)
  def with_uom_right(%{} = field, uom), do: Map.put(field, :uom_right, uom)

  def with_scale(%{type: :numeric} = field, scale) when is_integer(scale),
    do: Map.put(field, :scale, scale)

  def checkbox(id, value \\ true) do
    field(id, :boolean)
    |> Map.put(:value, value)
  end

  def radio_button(id, value) do
    field(id, :option)
    |> Map.put(:value, value)
  end

  def date(id) do
    field(id, :date)
  end

  def options(id) do
    field(id, :segment_options)
  end

  def with_option(%{type: :segment_options} = item, id, title \\ nil, description \\ nil) do
    options =
      (Map.get(item, :options) || [])
      |> List.insert_at(-1, %{
        id: id,
        title: List.wrap(title),
        description: List.wrap(description)
      })

    Map.put(item, :options, options)
  end

  def spacer, do: info()

  def info, do: base(:info)

  def content(url) do
    base(:info)
    |> Map.put(:url, URI.to_string(CampaignHelpers.get_resource_uri(url)))
  end

  def action(%CampaignAction{} = action) do
    item =
      base(:action)
      |> Map.put(:field, action.id)
      |> Map.put(:action, action.type)

    action
    |> Map.merge(item)
  end

  def with_title(item, title_or_titles),
    do: Map.put(item, :title, List.wrap(Map.get(item, :title)) ++ List.wrap(title_or_titles))

  def with_description(item, text_or_texts),
    do:
      Map.put(
        item,
        :description,
        List.wrap(Map.get(item, :description)) ++ List.wrap(text_or_texts)
      )

  def with_label(item, label), do: Map.put(item, :label, Enum.at(List.wrap(label), 0))

  def with_display_class(item, class_or_classes),
    do: CampaignHelpers.with_display_class(item, class_or_classes)

  def with_hint(item, hint), do: Map.put(item, :hint, Enum.at(List.wrap(hint), 0))

  def with_indent(item, level) when is_integer(level),
    do:
      item
      |> with_indent_left(level)
      |> with_indent_right(level)

  def with_indent_left(item, level) when is_integer(level), do: Map.put(item, :level_left, level)

  def with_indent_right(item, level) when is_integer(level),
    do: Map.put(item, :level_right, level)

  def depends_on_value(item, field, value_or_values, include_or_exclude \\ true)
      when is_atom(field) and is_boolean(include_or_exclude),
      do: CampaignHelpers.depends_on_value(item, field, value_or_values, include_or_exclude)

  def chart(id, %{type: :chart} = chart) when is_atom(id), do: Map.merge(chart, field(id, :chart))
end
