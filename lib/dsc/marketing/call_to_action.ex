defmodule DriversSeatCoop.Marketing.CallToAction do
  alias DriversSeatCoop.Marketing.CampaignHelpers
  alias DriversSeatCoop.Marketing.CampaignState

  def new(id) when is_atom(id) do
    CampaignHelpers.new_campaign(id, :content_cta)
    |> Map.merge(%{
      get_headers: fn %CampaignState{} -> [] end,
      get_footers: fn %CampaignState{} -> [] end,
      get_content_url: fn %CampaignState{} -> nil end,
      get_actions: fn %CampaignState{} -> [] end
    })
  end

  def with_header(cta, fx_or_values),
    do: CampaignHelpers.wrap_function_returns_array(cta, :get_headers, fx_or_values)

  def with_footer(cta, fx_or_values),
    do: CampaignHelpers.wrap_function_returns_array(cta, :get_footers, fx_or_values)

  def with_content_url(cta, fx_or_value),
    do: CampaignHelpers.set_content_url_function(cta, :get_content_url, fx_or_value)

  def with_action(cta, fx_or_actions),
    do: CampaignHelpers.wrap_function_returns_array(cta, :get_actions, fx_or_actions)

  def with_conditional_action(cta, conditional_fx, action_or_actions)
      when is_function(conditional_fx),
      do: CampaignHelpers.with_conditional_action(cta, conditional_fx, action_or_actions)

  def with_display_class(cta, class_or_classes),
    do: CampaignHelpers.with_display_class(cta, class_or_classes)

  def get_config(
        %{
          type: :content_cta
        } = campaign,
        %CampaignState{} = state
      ) do
    %{
      header: campaign.get_headers.(state),
      footer: campaign.get_footers.(state),
      content_url: campaign.get_content_url.(state),
      actions: campaign.get_actions.(state)
    }
  end
end
