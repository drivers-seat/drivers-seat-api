defmodule DriversSeatCoop.Marketing.Campaigns.Examples do
  alias DriversSeatCoop.GigAccounts
  alias DriversSeatCoop.Goals
  alias DriversSeatCoop.Marketing.CallToAction
  alias DriversSeatCoop.Marketing.Campaign
  alias DriversSeatCoop.Marketing.CampaignAction
  alias DriversSeatCoop.Marketing.CampaignState
  alias DriversSeatCoop.Marketing.Survey
  alias DriversSeatCoop.Repo

  require Logger

  alias DriversSeatCoop.Marketing.CallToAction
  alias DriversSeatCoop.Marketing.Campaign
  alias DriversSeatCoop.Marketing.CampaignAction

  def cta do
    cta =
      CallToAction.new(:example_cta)
      |> CallToAction.with_content_url(
        "https://blog.driversseat.co/campaigns/whatsapp-community/intro-whatsapp-community"
      )

    cta =
      cta
      |> CallToAction.with_header(fn %CampaignState{} = state ->
        "Hi, #{state.user.first_name}"
      end)
      |> CallToAction.with_header(fn %CampaignState{} = state ->
        "You're using an #{state.device.device_platform} device"
      end)

    # cta =
    #   CallToAction.with_header(cta, [
    #     "Example CTA Header",
    #     "more header text"
    #   ])

    # cta =
    #   CallToAction.with_footer(cta, [
    #     "Example CTA Footer",
    #     "more footer text"
    #   ])

    cta = Campaign.with_category(cta, :interrupt)

    cta = cta
    |> CallToAction.with_action(
      CampaignAction.new(:join, :accept, "Join our community!")
      |> CampaignAction.with_url("https://chat.whatsapp.com/XXXXXXXXXXXXXXXXXXXXXX")
    )
    |> CallToAction.with_action(
      CampaignAction.new(:join, :accept, "Invite a friend!")
      |> CampaignAction.with_url("/marketing/referral/generate/app_invite_menu")
    )

    cta =
      cta
      |> CallToAction.with_action(CampaignAction.default_postpone_tool())


    # cta =
    #   cta
    #   |> CallToAction.with_action(CampaignAction.default_close_tool())

    # cta =
    #   cta
    #   |> CallToAction.with_action(CampaignAction.default_dismiss_tool())

    cta =
      cta
      |> CallToAction.with_action(
        CampaignAction.default_help_tool("Pre populate the help message with this text")
      )

    cta = CallToAction.with_action(cta, CampaignAction.default_postpone_link())
    cta = CallToAction.with_action(cta, CampaignAction.default_dismiss_link())

    cta = CallToAction.with_action(cta, CampaignAction.default_close_tool())
    cta = CallToAction.with_action(cta, CampaignAction.default_dismiss_tool())
    cta = CallToAction.with_action(cta, CampaignAction.default_help_tool("Help"))

    cta
  end

  def survey do
    Survey.new(:example_cta)
    |> is_qualified_two_days_after_sign_up()
    |> is_qualified_platform_ios()
  end

  def is_qualified_two_days_after_sign_up(campaign) do
    Campaign.is_qualified(campaign, fn %CampaignState{} = state ->
      two_days_after_sign_up =
        state.user.inserted_at
        |> NaiveDateTime.add(172_800, :second)

      NaiveDateTime.compare(two_days_after_sign_up, NaiveDateTime.utc_now()) in [:lt, :eq]
    end)
  end

  def is_qualified_platform_ios(campaign) do
    Campaign.is_qualified(campaign, fn %CampaignState{} = state ->
      state.device.device_platform == "ios"
    end)
  end

  def is_qualified_has_gig_accounts_connected(campaign) do
    Campaign.is_qualified(campaign, fn %CampaignState{} = state ->
      GigAccounts.query()
      |> GigAccounts.query_filter_user(state.user.id)
      |> GigAccounts.query_filter_is_connected()
      |> Repo.exists?()
    end)
  end

  def is_qualified_has_gig_accounts_with_problems(campaign) do
    Campaign.is_qualified(campaign, fn %CampaignState{} = state ->
      GigAccounts.query()
      |> GigAccounts.query_filter_user(state.user.id)
      |> GigAccounts.query_filter_is_connected(false)
      |> Repo.exists?()
    end)
  end

  def is_qualified_app_version(campaign) do
    campaign
    |> Campaign.include_app_version(">=1.0.0")
    |> Campaign.include_app_version("<1.0.0")
  end

  def with_category_interrupt(campaign) do
    Campaign.with_category(campaign, [:interrupt, :to_do])
  end

  def with_category_dynamic(campaign) do
    Campaign.with_category(campaign, fn %CampaignState{} = state ->
      has_goals =
        Goals.query_goals()
        |> Goals.query_goals_filter_user(state.user.id)
        |> Goals.query_goals_filter_type(:earnings)
        |> Repo.exists?()

      has_gig_account =
        GigAccounts.query()
        |> GigAccounts.query_filter_user(state.user.id)
        |> GigAccounts.query_filter_is_connected()
        |> Repo.exists?()

      location_tracking_configured = state.device.location_tracking_config_status == "configured"

      if has_goals and has_gig_account and location_tracking_configured,
        do: [],
        else: [:to_do]
    end)
  end

  def with_category_two_days_after_sign_up(campaign) do
    Campaign.with_category(campaign, fn %CampaignState{} = state ->
      two_days_after_sign_up =
        state.user.inserted_at
        |> NaiveDateTime.add(172_800, :second)

      if NaiveDateTime.compare(two_days_after_sign_up, NaiveDateTime.utc_now()) in [:lt, :eq],
        do: [:interrupt],
        else: []
    end)
  end
end
