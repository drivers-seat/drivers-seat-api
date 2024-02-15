defmodule DriversSeatCoop.Marketing.CampaignHelpers do
  alias DriversSeatCoop.Marketing.CampaignState

  @campaign_content_relative_path "web/campaigns"

  def new_campaign(id, type) when is_atom(id) and type in [:content_cta, :survey, :checklist] do
    %{
      id: id,
      type: type,
      get_categories: fn %CampaignState{} -> [] end,
      app_versions_included: nil,
      app_versions_excluded: nil,
      display_class: nil,
      get_preview: fn %CampaignState{} -> nil end,
      is_qualified: fn %CampaignState{} -> true end,
      on_present: fn %CampaignState{} = state ->
        now = DateTime.utc_now()

        state.participant
        |> Map.put(:presented_on_first, state.participant.presented_on_first || now)
        |> Map.put(:presented_on_last, now)
      end,
      on_accept: fn %CampaignState{} = state, action_id ->
        state.participant
        |> Map.put(:accepted_on, DateTime.utc_now())
        |> Map.put(:accepted_action, action_id)
      end,
      on_dismiss: fn %CampaignState{} = state, action_id ->
        state.participant
        |> Map.put(:dismissed_on, DateTime.utc_now())
        |> Map.put(:dismissed_action, action_id)
      end,
      on_postpone: fn %CampaignState{} = state, action_id, postpone_minutes ->
        postponed_until =
          DateTime.utc_now()
          |> DateTime.add(postpone_minutes * 60, :second)

        state.participant
        |> Map.put(:postponed_until, postponed_until)
        |> Map.put(:postponed_action, action_id)
      end,
      on_custom_action: fn %CampaignState{} = state, _action_id -> state.participant end
    }
  end

  def wrap_function_returns_array(campaign, prop, fx) when is_function(fx) and is_atom(prop) do
    inner_fx = Map.get(campaign, prop)

    new_fx =
      if is_nil(inner_fx) do
        fx
      else
        fn %CampaignState{} = state ->
          List.wrap(inner_fx.(state)) ++ List.wrap(fx.(state))
        end
      end

    Map.put(campaign, prop, new_fx)
  end

  def wrap_function_returns_array(campaign, prop, value) when is_atom(prop) do
    fx = fn %CampaignState{} = _state -> List.wrap(value) end
    wrap_function_returns_array(campaign, prop, fx)
  end

  def wrap_function_returns_state(campaign, prop, fx) when is_function(fx) and is_atom(prop) do
    inner_fx = Map.get(campaign, prop)

    new_fx =
      if is_nil(inner_fx) do
        fx
      else
        fn %CampaignState{} = state ->
          state = inner_fx.(state)
          fx.(state)
        end
      end

    Map.put(campaign, prop, new_fx)
  end

  def wrap_action_handler_function(campaign, prop, fx) when is_function(fx) and is_atom(prop) do
    inner_fx = Map.get(campaign, prop)

    new_fx =
      if is_nil(inner_fx) do
        fx
      else
        fn %CampaignState{} = state, action_id ->
          state = Map.put(state, :participant, inner_fx.(state, action_id) || state.participant)
          fx.(state, action_id)
        end
      end

    Map.put(campaign, prop, new_fx)
  end

  def set_function(campaign, prop, fx) when is_function(fx) and is_atom(prop),
    do: Map.put(campaign, prop, fx)

  def set_function(campaign, prop, value) when is_atom(prop),
    do: Map.put(campaign, prop, fn %CampaignState{} -> value end)

  @doc """
  if a local referernce, make sure to prepend the public host name
  example: /onboarding/clock.jpg  ->  https://wwww.driversseat.co/web/campaigns/onboarding/clock.jpg"
  example: http://xyz.com/onboarding/clock.jpg  ->  http://xyz.com/onboarding/clock.jpg
  """
  def set_content_url_function(campaign, prop, fx) when is_function(fx) and is_atom(prop) do
    fx = fn %CampaignState{} = state ->
      url = fx.(state)
      url = get_resource_uri(url)
      URI.to_string(url)
    end

    Map.put(campaign, prop, fx)
  end

  def set_content_url_function(campaign, prop, url) when is_atom(prop) do
    url = get_resource_uri(url)
    Map.put(campaign, prop, fn %CampaignState{} -> URI.to_string(url) end)
  end

  def with_conditional_action(obj, conditional_fx, action_or_actions)
      when is_function(conditional_fx) do
    wrap_function_returns_array(obj, :get_actions, fn %CampaignState{} = state ->
      if conditional_fx.(state), do: action_or_actions, else: nil
    end)
  end

  def depends_on_value(obj, field, value_or_values, include \\ true)
      when is_atom(field) and is_boolean(include) do
    list_type = if include, do: :include_values, else: :exclude_values

    deps = Map.get(obj, :dependencies) || %{}

    field_deps = Map.get(deps, field) || %{}

    dep_values = List.wrap(Map.get(field_deps, list_type)) ++ List.wrap(value_or_values)

    field_deps = Map.put(field_deps, list_type, dep_values)

    deps = Map.put(deps, field, field_deps)

    Map.put(obj, :dependencies, deps)
  end

  def with_display_class(obj, class_or_classes),
    do:
      Map.put(
        obj,
        :display_class,
        List.wrap(obj.display_class) ++ List.wrap(class_or_classes)
      )

  @doc """
  Get campaign static resource will pass through an absolute url (http://.....)
  If a relative path supplied, reformat it to point back to the web server
  example:  /images/test.png -> http://app.driversseat.co/web/campaigns/images/test.jpg
  """
  def get_resource_uri(url) do
    uri = URI.new!(url)

    if is_nil(uri.host) do
      url =
        url
        |> String.trim()
        |> String.trim_leading("/")

      relative_uri =
        "#{@campaign_content_relative_path}/#{url}"
        |> URI.new!()

      get_host_uri()
      |> URI.merge(relative_uri)
    else
      uri
    end
  end

  # Returns the externally facing host information for the app
  defp get_host_uri do
    url_config =
      Application.fetch_env!(:dsc, DriversSeatCoopWeb.Endpoint)
      |> Keyword.fetch!(:url)

    uri = %URI{
      host: Keyword.get(url_config, :host),
      port: Keyword.get(url_config, :port),
      scheme: Keyword.get(url_config, :scheme)
    }

    if is_nil(uri.scheme) and uri.port == 443,
      do: Map.put(uri, :scheme, "https"),
      else: uri
  end
end
