defmodule DriversSeatCoop.Marketing.Campaigns.Examples do
  alias DriversSeatCoop.GigAccounts
  alias DriversSeatCoop.Accounts
  alias DriversSeatCoop.Goals
  alias DriversSeatCoop.Marketing.CallToAction
  alias DriversSeatCoop.Marketing.Campaign
  alias DriversSeatCoop.Marketing.CampaignAction
  alias DriversSeatCoop.Marketing.CampaignState
  alias DriversSeatCoop.Marketing.CampaignPreview
  alias DriversSeatCoop.Marketing.Checklist
  alias DriversSeatCoop.Marketing.ChecklistItem
  alias DriversSeatCoop.Marketing.Survey
  alias DriversSeatCoop.Marketing.SurveyItem
  alias DriversSeatCoop.Marketing.SurveySection
  alias DriversSeatCoop.Repo
  alias DriversSeatCoop.GigAccounts
  alias DriversSeatCoop.Util.TextUtil

  require Logger

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

    cta =
      cta
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
    cta = 
    cta
    |> CallToAction.with_action(CampaignAction.default_dismiss_link())
      |> CampaignAction.with_reengage_delay(90)
      

    cta = CallToAction.with_action(cta, CampaignAction.default_close_tool())
    cta = CallToAction.with_action(cta, CampaignAction.default_dismiss_tool())
    cta = CallToAction.with_action(cta, CampaignAction.default_help_tool("Help"))
    

    cta =
      cta
      |> CallToAction.with_conditional_action(
        fn %CampaignState{} = state ->
          is_nil(state.participant.postponed_until)
        end,
        CampaignAction.new(:remind_later, :postpone, "Maybe Later")
        |> CampaignAction.with_postpone_minutes(90)
        |> CampaignAction.as_link()
      )

    cta =
      cta
      |> CallToAction.with_action(fn %CampaignState{} = state ->
        account_age_seconds = NaiveDateTime.diff(NaiveDateTime.utc_now(), state.user.inserted_at)

        if account_age_seconds >= 432_000 do
          CampaignAction.new(:blog, :custom, [
            "Get the lastest Driver News",
            "Check out the Driver's Seat Blog"
          ])
          |> CampaignAction.with_url("https://blog.driversseat.co")
        else
          []
        end
      end)

    cta
  end

  @example_survey :goals_survey
  def survey do
    Survey.new(:xyz)
    |> Campaign.with_category(:interrupt)
    |> Survey.with_section(SurveySection.new(:page_1))
    |> Survey.with_section(
      SurveySection.new(:welcome)
      |> SurveySection.with_title("Example Survey")
      |> SurveySection.with_item(
        SurveyItem.info()
        |> SurveyItem.with_title("Here's How You Can help")
        |> SurveyItem.with_description(
          "Getting Involved is easy and only takes a few moments of your time"
        )
      )
      |> SurveySection.with_item(SurveyItem.spacer())
      |> SurveySection.with_item(SurveyItem.content("#{@example_survey}/welcome.png"))
      |> SurveySection.with_item(SurveyItem.spacer())
      |> SurveySection.with_item(
        SurveyItem.content("#{@example_survey}/welcome.png")
        |> SurveyItem.with_indent(2)
      )
      |> SurveySection.with_item(SurveyItem.spacer())
      |> SurveySection.with_item(
        SurveyItem.text(:first_name, :short_text)
        |> SurveyItem.with_hint("first name")
      )
      |> SurveySection.with_item(SurveyItem.spacer())
      |> SurveySection.with_item(
        SurveyItem.text(:first_name, :long_text)
        |> SurveyItem.with_hint("Tell us what you like about Driver's Seat")
      )
      |> SurveySection.with_item(SurveyItem.spacer())
      |> SurveySection.with_item([
        SurveyItem.radio_button(:hours_per_week, :lt_10)
        |> SurveyItem.with_title("Less than 10 hr./hweek"),
        SurveyItem.radio_button(:hours_per_week, :btwn_10_30)
        |> SurveyItem.with_title("Between 10 and 30 hr./week"),
        SurveyItem.radio_button(:hours_per_week, :btwn_30_50)
        |> SurveyItem.with_title("Between 30 and 50 hr./week"),
        SurveyItem.radio_button(:hours_per_week, :gt_50)
        |> SurveyItem.with_title("More than 50 hr./week")
      ])
      |> SurveySection.with_item(SurveyItem.spacer())
      |> SurveySection.with_item(
        SurveyItem.checkbox(:sets_goals, :yes)
        |> SurveyItem.with_title("Do you set earning gols?")
        |> SurveyItem.with_description(
          "Do you track your earnings and compare to a goal that you have set?"
        )
      )
      |> SurveySection.with_item(SurveyItem.spacer())
      |> SurveySection.with_item([
        SurveyItem.info()
        |> SurveyItem.with_title("Which types of goals do you track?"),
        SurveyItem.checkbox(:goal_types, :earnings)
        |> SurveyItem.with_description("Earnings Goals")
        |> SurveyItem.with_indent_left(1),
        SurveyItem.checkbox(:goal_types, :earning_per_mile)
        |> SurveyItem.with_description("Dollars/Mile")
        |> SurveyItem.with_indent_left(1),
        SurveyItem.checkbox(:goal_types, :dollars_per_hour)
        |> SurveyItem.with_description("Dollars/Hour")
        |> SurveyItem.with_indent_left(1),
        SurveyItem.checkbox(:goal_types, :total_hours)
        |> SurveyItem.with_description("Total Hours")
        |> SurveyItem.with_indent_left(1)
      ])
      |> SurveySection.with_item(SurveyItem.spacer())
      |> SurveySection.with_item(
        SurveyItem.numeric(:hours_per_month)
        # optional: whole number
        |> SurveyItem.with_scale(0)
        # optional
        |> SurveyItem.with_label("monthly")
        # optional
        |> SurveyItem.with_uom_right("hours")
      )
      |> SurveySection.with_item(SurveyItem.spacer())
      |> SurveySection.with_item(
        SurveyItem.currency(:monthly_goal)
        # optional: whole dollar
        |> SurveyItem.with_scale(0)
        # optional
        |> SurveyItem.with_uom_right("/month")
      )
      |> SurveySection.with_item(SurveyItem.spacer())
      |> SurveySection.with_item(
        SurveyItem.date(:started_gig_work)
        |> SurveyItem.with_title("Start Date")
      )
      |> SurveySection.with_item(SurveyItem.spacer())
      |> SurveySection.with_item(
        SurveyItem.options(:rating)
        |> SurveyItem.with_option(:strong_disagree, "<<")
        |> SurveyItem.with_option(:disagree, "<")
        |> SurveyItem.with_option(:neutral, "0")
        |> SurveyItem.with_option(:agree, ">")
        |> SurveyItem.with_option(:strong_agree, ">>")
        |> SurveyItem.with_uom_left("← disagree")
        |> SurveyItem.with_uom_right("agree →")
      )
      |> SurveySection.with_item(SurveyItem.spacer())
      |> SurveySection.with_item([
        SurveyItem.info()
        |> SurveyItem.with_title("Get a kickstart on your taxes")
        |> SurveyItem.with_description(
          "Download your mileage info so you can take a deduction on your taxes."
        ),
        SurveyItem.spacer(),
        SurveyItem.action(CampaignAction.new(:download_data, :custom, "Download My Data")),
        SurveyItem.spacer(),
        SurveyItem.info()
        |> SurveyItem.with_title("Signing up is easy and free")
        |> SurveyItem.with_description("Tell us a little about yourself"),
        SurveyItem.spacer(),
        SurveyItem.text(:fname)
        |> SurveyItem.with_hint("first name")
      ])
      |> SurveySection.with_item(SurveyItem.spacer())
      |> SurveySection.with_item([
        SurveyItem.info()
        |> SurveyItem.with_title("Tell us about your daily earning goal"),
        SurveyItem.spacer(),
        SurveyItem.radio_button(:daily_goal_type, :same_every_day)
        |> SurveyItem.with_title("Same Every Day")
        |> SurveyItem.with_description(
          "I try to earn the same amount of money every day that I work"
        ),
        SurveyItem.currency(:daily_goal_all)
        |> SurveyItem.with_indent_left(1)
        |> SurveyItem.with_hint("every day")
        |> SurveyItem.depends_on_value(:daily_goal_type, :same_every_day),
        SurveyItem.spacer(),
        SurveyItem.radio_button(:daily_goal_type, :different_each_day)
        |> SurveyItem.with_title("Different for Each Day")
        |> SurveyItem.with_description("My earning goal depends on the day of the week"),
        SurveyItem.currency(:daily_goal_mon)
        |> SurveyItem.with_indent_left(1)
        |> SurveyItem.with_label("Monday")
        |> SurveyItem.depends_on_value(:daily_goal_type, :different_each_day),
        SurveyItem.currency(:daily_goal_tue)
        |> SurveyItem.with_indent_left(1)
        |> SurveyItem.with_label("Tuesday")
        |> SurveyItem.depends_on_value(:daily_goal_type, :different_each_day),
        SurveyItem.currency(:daily_goal_wed)
        |> SurveyItem.with_indent_left(1)
        |> SurveyItem.with_label("Wednesday")
        |> SurveyItem.depends_on_value(:daily_goal_type, :different_each_day)
      ])
      |> SurveySection.with_item(SurveyItem.spacer())
      |> SurveySection.with_item(
        SurveyItem.currency(:dollars_per_mile)
        |> SurveyItem.with_title("Dollars Per Mile")
        |> SurveyItem.with_uom_right("/mile")
      )
      |> SurveySection.validate_required(:dollars_per_mile)
      |> SurveySection.validate_min_value(:dollars_per_mile, 0.01)
      |> SurveySection.with_item(SurveyItem.spacer())
      |> SurveySection.with_item([
        SurveyItem.info()
        |> SurveyItem.with_title("Which days do you work?"),
        SurveyItem.checkbox(:work_days, :monday)
        |> SurveyItem.with_description("Monday")
        |> SurveyItem.with_indent_left(1),
        SurveyItem.checkbox(:work_days, :tuesday)
        |> SurveyItem.with_description("Tuesday")
        |> SurveyItem.with_indent_left(1),
        SurveyItem.checkbox(:work_days, :wednesday)
        |> SurveyItem.with_description("Wednesday")
        |> SurveyItem.with_indent_left(1)
      ])
      |> SurveySection.validate_required(:work_days)
      # |> SurveySection.hide_page_navigation()
      # |> SurveySection.hide_page_markers()
    )
    |> Survey.with_section(SurveySection.new(:page_2))

    #     section = SurveySection.new(:test)

    #   section
    #   |> SurveySection.with_item(
    #     SurveyItem.content("http://www.google.com/img.png")
    #     |> SurveyItem.with_indent(2)
    #   )

    #   section
    #   |> SurveySection.with_item(SurveyItem.text(:first_name, :short_text))

    #   section
    #   |> SurveySection.with_item(
    #     SurveyItem.text(:feedback, :long_text)
    #     |> SurveyItem.with_hint()
    #   )

    #   section
    #   |> SurveySection.with_item([
    #     SurveyItem.radio_button(:hours_per_week, :lt_10)
    #     |> SurveyItem.with_title("Less than 10 hr./hweek"),
    #     SurveyItem.radio_button(:hours_per_week, :btwn_10_30)
    #     |> SurveyItem.with_title("Between 10 and 30 hr./week"),
    #     SurveyItem.radio_button(:hours_per_week, :btwn_30_50)
    #     |> SurveyItem.with_title("Between 30 and 50 hr./week"),
    #     SurveyItem.radio_button(:hours_per_week, :gt_50)
    #     |> SurveyItem.with_title("More than 50 hr./week")
    #   ])

    #   section
    #   |> SurveySection.with_item([
    #     SurveyItem.checkbox(:agree_to_terms)
    #   ])

    #   section
    #   |> SurveySection.with_item([
    #     SurveyItem.info()
    #     |> SurveyItem.with_title("Which types of goals do you track?"),
    #     SurveyItem.checkbox(:goal_types, :earnings)
    #     |> SurveyItem.with_description("Earnings Goals")
    #     |> SurveyItem.with_indent_left(1),
    #     SurveyItem.checkbox(:goal_types, :earning_per_mile)
    #     |> SurveyItem.with_description("Dollars/Mile")
    #     |> SurveyItem.with_indent_left(1),
    #     SurveyItem.checkbox(:goal_types, :dollars_per_hour)
    #     |> SurveyItem.with_description("Dollars/Hour")
    #     |> SurveyItem.with_indent_left(1),
    #     SurveyItem.checkbox(:goal_types, :total_hours)
    #     |> SurveyItem.with_description("Total Hours")
    #     |> SurveyItem.with_indent_left(1)
    #   ])

    #   Survey.new(:connect_gig_accts)
    #   |> Campaign.is_qualified(fn %CampaignState{} = state ->
    #     # it has been less that 5 days
    #     if NaiveDateTime.diff(NaiveDateTime.utc_now(), state.user.inserted_at) <>
    #          @five_days_seconds do
    #       false
    #     else
    #       # user has not already connected a gig account
    #       not (GigAccounts.query()
    #            |> GigAccounts.query_filter_user(state.user.id)
    #            |> GigAccounts.query_filter_is_connected()
    #            |> Repo.exists?())
    #     end
    #   end)
  end

  @example_checklist :checklist
  def checklist do
    Checklist.new(@example_checklist)
    |> Campaign.with_category(:to_dos)
    |> Checklist.with_title(fn %CampaignState{} = state ->
      [
        "Hello #{state.user.first_name}",
        "Here's your daily rundown"
      ]
    end)
    # |> Checklist.with_description("Use this checklist to make sure you're on track to meet your goals")
    |> Checklist.with_item(
      ChecklistItem.new(:task_1)
      # |> ChecklistItem.with_title("Hello")
      |> ChecklistItem.with_description(["Good Morning!", "You delicate soul"])
      |> ChecklistItem.with_status(:requires_attention)
    )
    |> Checklist.with_item(fn %CampaignState{} = state ->
      gig_accounts =
        GigAccounts.query()
        |> GigAccounts.query_filter_user(state.user.id)
        |> Repo.all()

      employers_with_problems =
        gig_accounts
        |> Enum.filter(fn g -> not g.is_connected end)
        |> Enum.map(fn g -> String.capitalize(g.employer) end)

      item =
        ChecklistItem.new(:gig_accounts)
        |> ChecklistItem.with_title("Connect Your Gig Accounts")
        |> ChecklistItem.with_action(
          CampaignAction.new(:gig_accts, :custom, "gig accounts")
          |> CampaignAction.with_url("gig-accounts")
        )

      cond do
        # No Accounts
        not Enum.any?(gig_accounts) ->
          item
          |> ChecklistItem.with_status(:not_started)
          |> ChecklistItem.with_description(
            "Connect your gig accounts so we can anaylze your earnings"
          )

        # Accounts with problems
        Enum.any?(employers_with_problems) ->
          desc = TextUtil.friendly_csv_list(employers_with_problems, "and")
          desc = "Your #{desc} account(s) require attention."

          item
          |> ChecklistItem.with_status(:requires_attention)
          |> ChecklistItem.with_description(desc)

        # otherwise complete
        true ->
          item
          |> ChecklistItem.with_description(
            "You have #{Enum.count(gig_accounts)} account(s) connected."
          )
          |> ChceklistItem.with_status(:complete)
      end
    end)
    |> Checklist.show_progress()
    |> Checklist.with_action(CampaignAction.new(:wee, :help, "Help"))
    |> Checklist.with_action([
      CampaignAction.new(:wee, :help, "Help")
      |> CampaignAction.as_link(),
      CampaignAction.new(:wee, :help, "Help")
      |> CampaignAction.as_link()
      # CampaignAction.new(:wee, :help, "Help")
      # |> CampaignAction.as_header_tool()
    ])
  end

  @example_preview :join_community
  def previews do
    [
      CallToAction.new(:preview_1)
      |> Campaign.with_category(:info)
      |> Campaign.with_preview(
        CampaignPreview.new()
        |> CampaignPreview.with_left_image_url("#{@example_preview}/preview.png")
        |> CampaignPreview.with_action([
          CampaignAction.new(:join, :custom, "Join our community!")
          |> CampaignAction.with_url("/marketing/custom/example_custom_page"),
          CampaignAction.new(:dismiss, :dismiss, "No Thanks")
          |> CampaignAction.as_header_tool(),
          CampaignAction.new(:dismiss, :help, "No Thanks")
          |> CampaignAction.as_header_tool(),
          CampaignAction.new(:join, :custom, "No Thanks")
          |> CampaignAction.as_link()
        ])
      ),
      CallToAction.new(:preview_2)
      |> Campaign.with_category(:info)
      |> Campaign.with_preview(
        CampaignPreview.new()
        |> CampaignPreview.with_left_image_url("#{@example_preview}/logo-small.png")
        |> CampaignPreview.with_title([
          "Want to help others?",
        ])
        # |> CampaignPreview.with_description([
        #   "Have you ever wondered how you can up your game and helo others at the same time?",
        #   "Become a mentor to other drivers.  It's quick and easy."
        # ])
        |> CampaignPreview.with_action([
          CampaignAction.new(:mentor, :accept, "Find out more!"),
          CampaignAction.new(:dismiss, :dismiss, "X")
          |> CampaignAction.as_header_tool(),
          CampaignAction.new(:dismiss, :help, "No Thanks")
          |> CampaignAction.as_header_tool(),
        ])
      ),
      CallToAction.new(:preview_3)
      |> Campaign.with_category(:info)
      |> Campaign.with_preview(
        CampaignPreview.new()
        |> CampaignPreview.with_left_image_url("#{@example_preview}/logo-small.png")
        |> CampaignPreview.with_title([
          "Want to help others?",
        ])
        |> CampaignPreview.with_description([
          "Have you ever wondered how you can up your game and helo others at the same time?",
          "Become a mentor to other drivers.  It's quick and easy."
        ])
        |> CampaignPreview.with_action([
          CampaignAction.new(:mentor, :accept, "Find out more!"),
          CampaignAction.new(:dismiss, :dismiss, "X")
          |> CampaignAction.as_header_tool(),
          CampaignAction.new(:dismiss, :help, "No Thanks")
          |> CampaignAction.as_header_tool(),
        ])
      ),
      CallToAction.new(:preview_4)
      |> Campaign.with_category(:info)
      |> Campaign.with_preview(
        CampaignPreview.new()
        |> CampaignPreview.with_right_image_url("#{@example_preview}/logo-small.png")
        |> CampaignPreview.with_title([
          "Want to help others?",
        ])
        |> CampaignPreview.with_description([
          "Have you ever wondered how you can up your game and helo others at the same time?",
          "Become a mentor to other drivers.  It's quick and easy."
        ])
        |> CampaignPreview.with_action([
          CampaignAction.new(:mentor, :accept, "Find out more!"),
          CampaignAction.new(:dismiss, :dismiss, "X")
          |> CampaignAction.as_header_tool(),
          CampaignAction.new(:dismiss, :help, "No Thanks")
          |> CampaignAction.as_header_tool(),
        ])
      ),
      CallToAction.new(:preview_5)
      |> Campaign.with_category(:info)
      |> Campaign.with_preview(
        CampaignPreview.new()
        |> CampaignPreview.with_content_url("goals_intro_link_accounts/index.html")
        # |> CampaignPreview.with_left_image_url("#{@example_preview}/logo-small.png")
        # |> CampaignPreview.with_right_image_url("#{@example_preview}/logo-small.png")
      )
      
    ]
  end

  def custom_page do
    [
      CallToAction.new(:custom_1)
      |> Campaign.with_category(:custom_top)
      |> Campaign.with_preview(
        CampaignPreview.new()
        |> CampaignPreview.with_title("Top Card")
        |> CampaignPreview.with_left_image_url("#{@example_preview}/logo-small.png")
      ),
      CallToAction.new(:custom_2)
      |> Campaign.with_category(:custom_horizontal_1)
      |> Campaign.with_preview(
        CampaignPreview.new()
        |> CampaignPreview.with_title("Horizontal #1")
        |> CampaignPreview.with_left_image_url("#{@example_preview}/logo-small.png")
      ),
      CallToAction.new(:custom_3)
      |> Campaign.with_category(:custom_horizontal_1)
      |> Campaign.with_preview(
        CampaignPreview.new()
        |> CampaignPreview.with_title("Horizontal #2")
        |> CampaignPreview.with_description("Here's a nice description for the Custom card #2")
      ),
      CallToAction.new(:custom_4)
      |> Campaign.with_category(:custom_horizontal_1)
      |> Campaign.with_preview(
        CampaignPreview.new()
        |> CampaignPreview.with_title("Horizontal #3")
        |> CampaignPreview.with_description("Here's a nice description for the Custom card #3")
      ),
      CallToAction.new(:custom_5)
      |> Campaign.with_category(:custom_horizontal_2)
      |> Campaign.with_preview(
        CampaignPreview.new()
        |> CampaignPreview.with_title("Slider #1")
        |> CampaignPreview.with_description("Here's the slider #1")
        |> CampaignPreview.with_left_image_url("#{@example_preview}/logo-small.png")
      ),
      CallToAction.new(:custom_6)
      |> Campaign.with_category(:custom_horizontal_2)
      |> Campaign.with_preview(
        CampaignPreview.new()
        |> CampaignPreview.with_title("Slider #2")
        |> CampaignPreview.with_description("Heres a description for slider card #2")
      ),
      CallToAction.new(:custom6)
      |> Campaign.with_category(:custom_vertical_2)
      |> Campaign.with_preview(
        CampaignPreview.new()
        |> CampaignPreview.with_left_image_url("#{@example_preview}/logo-small.png")
      ),
      CallToAction.new(:custom_7)
      |> Campaign.with_category(:custom_vertical_2)
      |> Campaign.with_preview(
        CampaignPreview.new()
        |> CampaignPreview.with_title("Vertical Card #2")
        |> CampaignPreview.with_description("Here's a nice description for the Custom card #3")
      )
    ]
  end
end