defmodule DriversSeatCoop.Marketing.Campaign do
  alias DriversSeatCoop.Accounts.User
  alias DriversSeatCoop.Marketing.CallToAction
  alias DriversSeatCoop.Marketing.CampaignHelpers
  alias DriversSeatCoop.Marketing.CampaignParticipant
  alias DriversSeatCoop.Marketing.CampaignState
  alias DriversSeatCoop.Marketing.Checklist
  alias DriversSeatCoop.Marketing.Survey

  def is_internal_account(%User{} = user) do
    String.contains?(String.downcase(user.email), "driversseat.co") or
      String.contains?(String.downcase(user.email), "dcalacci.net")
  end

  def with_category(campaign, fx_or_values),
    do: CampaignHelpers.wrap_function_returns_array(campaign, :get_categories, fx_or_values)

  def with_preview(campaign, fx_or_value),
    do: CampaignHelpers.set_function(campaign, :get_preview, fx_or_value)

  def include_app_version(campaign, version_or_versions),
    do:
      Map.put(
        campaign,
        :app_versions_included,
        List.wrap(Map.get(campaign, :app_versions_included, [])) ++ List.wrap(version_or_versions)
      )

  def exclude_app_version(campaign, version_or_versions),
    do:
      Map.put(
        campaign,
        :app_versions_excluded,
        List.wrap(Map.get(campaign, :app_versions_excluded, [])) ++ List.wrap(version_or_versions)
      )

  def is_qualified(campaign, fx_or_value),
    do: CampaignHelpers.set_function(campaign, :is_qualified, fx_or_value)

  def on_accept(campaign, fx),
    do: CampaignHelpers.wrap_action_handler_function(campaign, :on_accept, fx)

  def on_dismiss(campaign, fx),
    do: CampaignHelpers.wrap_action_handler_function(campaign, :on_dismiss, fx)

  def on_custom_action(campaign, fx),
    do: CampaignHelpers.wrap_action_handler_function(campaign, :on_custom_action, fx)

  def on_present(campaign, fx) when is_function(fx) do
    inner_fx = Map.get(campaign, :on_present)

    new_fx =
      if is_nil(inner_fx) do
        fx
      else
        fn %CampaignState{} = state ->
          state = Map.put(state, :participant, inner_fx.(state) || state.participant)
          fx.(state)
        end
      end

    Map.put(campaign, :on_present, new_fx)
  end

  def on_postpone(campaign, fx) when is_function(fx) do
    inner_fx = Map.get(campaign, :on_postpone)

    new_fx =
      if is_nil(inner_fx) do
        fx
      else
        fn %CampaignState{} = state, action_id, postpone_minutes ->
          state =
            Map.put(
              state,
              :participant,
              inner_fx.(state, action_id, postpone_minutes) || state.participant
            )

          fx.(state, action_id, postpone_minutes)
        end
      end

    Map.put(campaign, :on_postpone, new_fx)
  end

  def get_config(campaign, %CampaignState{} = state) do
    config =
      case campaign.type do
        :content_cta ->
          CallToAction.get_config(campaign, state)

        :survey ->
          Survey.get_config(campaign, state)

        :checklist ->
          Checklist.get_config(campaign, state)
      end

    config
    |> Map.merge(%{
      id: campaign.id,
      type: campaign.type,
      categories: campaign.get_categories.(state),
      display_class: campaign.display_class,
      preview: campaign.get_preview.(state)
    })
    |> Map.merge(CampaignParticipant.get_status_info(state.participant))
  end
end
