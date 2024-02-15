defmodule DriversSeatCoop.Marketing.Checklist do
  alias DriversSeatCoop.Marketing.CampaignAction
  alias DriversSeatCoop.Marketing.CampaignHelpers
  alias DriversSeatCoop.Marketing.CampaignState

  def new(id) when is_atom(id) do
    CampaignHelpers.new_campaign(id, :checklist)
    |> Map.merge(%{
      get_title: fn %CampaignState{} -> [] end,
      get_description: fn %CampaignState{} -> [] end,
      show_progress: false,
      get_actions: fn %CampaignState{} -> [] end,
      get_items: fn %CampaignState{} -> [] end
    })
  end

  def with_title(checklist, value_or_values),
    do: CampaignHelpers.wrap_function_returns_array(checklist, :get_title, value_or_values)

  def with_description(checklist, value_or_values),
    do: CampaignHelpers.wrap_function_returns_array(checklist, :get_description, value_or_values)

  def show_progress(checklist, value \\ true) when is_boolean(value),
    do: Map.put(checklist, :show_progress, value)

  def with_display_class(checklist, class_or_classes),
    do: CampaignHelpers.with_display_class(checklist, class_or_classes)

  def with_action(checklist, fx_or_actions),
    do: CampaignHelpers.wrap_function_returns_array(checklist, :get_actions, fx_or_actions)

  def with_conditional_action(checklist, conditional_fx, action_or_actions)
      when is_function(conditional_fx),
      do: CampaignHelpers.with_conditional_action(checklist, conditional_fx, action_or_actions)

  def with_item(checklist, fx_or_items),
    do: CampaignHelpers.wrap_function_returns_array(checklist, :get_items, fx_or_items)

  def with_conditional_item(checklist, conditional_fx, fx_item)
      when is_function(conditional_fx) and is_function(fx_item) do
    CampaignHelpers.wrap_function_returns_array(checklist, :get_items, fn %CampaignState{} = state ->
      if conditional_fx.(state), do: fx_item.(state), else: nil
    end)
  end

  def get_config(
        %{
          type: :checklist
        } = campaign,
        %CampaignState{} = state
      ) do
    %{
      title: campaign.get_title.(state),
      description: campaign.get_description.(state),
      show_progress: campaign.show_progress,
      actions: campaign.get_actions.(state),
      items: campaign.get_items.(state)
    }
  end
end

defmodule DriversSeatCoop.Marketing.ChecklistItem do
  alias DriversSeatCoop.Marketing.CampaignAction
  alias DriversSeatCoop.Marketing.CampaignHelpers

  def new(id) when is_atom(id) do
    %{
      id: id,
      description: nil,
      title: nil,
      status: :none,
      action: nil,
      display_class: nil,
      is_enabled: true
    }
  end

  def with_title(item, value_or_values),
    do: Map.put(item, :title, List.wrap(item.title) ++ List.wrap(value_or_values))

  def with_description(item, value_or_values),
    do: Map.put(item, :description, List.wrap(item.description) ++ List.wrap(value_or_values))

  def with_display_class(item, class_or_classes),
    do: CampaignHelpers.with_display_class(item, class_or_classes)

  def with_status(item, status)
      when status in [:new, :not_started, :in_process, :complete, :requires_attention, :none],
      do: Map.put(item, :status, status)

  def with_action(item, %CampaignAction{} = action), do: Map.put(item, :action, action)
end
