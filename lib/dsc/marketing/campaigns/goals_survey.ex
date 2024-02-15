defmodule DriversSeatCoop.Marketing.Campaigns.GoalsSurvey do
  alias DriversSeatCoop.Accounts
  alias DriversSeatCoop.Accounts.User
  alias DriversSeatCoop.Goals
  alias DriversSeatCoop.Marketing
  alias DriversSeatCoop.Marketing.Campaign
  alias DriversSeatCoop.Marketing.CampaignAction
  alias DriversSeatCoop.Marketing.CampaignState
  alias DriversSeatCoop.Marketing.Survey
  alias DriversSeatCoop.Marketing.SurveyItem
  alias DriversSeatCoop.Marketing.SurveySection
  alias DriversSeatCoop.Repo
  alias DriversSeatCoop.Util.DateTimeUtil

  require Logger

  @campaign_id :goals_survey

  def get_id, do: @campaign_id

  def instance do
    Survey.new(@campaign_id)
    # Exlcude users that already have goals
    |> Campaign.is_qualified(fn %CampaignState{} = state ->
      has_goals =
        Goals.query_goals()
        |> Goals.query_goals_filter_user(state.user.id)
        |> Repo.exists?()

      not has_goals
    end)
    |> Survey.with_section([
      get_section_welcome(),
      get_section_goal_types(),
      get_section_daily_goals(),
      get_section_weekly_goals(),
      get_section_monthly_goals(),
      get_section_other_strategies(),
      get_section_finish()
    ])
    |> Campaign.on_accept(fn %CampaignState{} = state, _action_id ->
      user = state.user
      additional_data = state.participant.additional_data || %{}
      Logger.warn("additional_data #{inspect(additional_data)}")
      create_goals_from_survey_responses(user, Map.get(additional_data, "data"))
      state.participant
    end)
  end

  defp get_section_welcome do
    SurveySection.new(:welcome)
    |> SurveySection.with_title("Boost your earnings by setting goals!")
    |> SurveySection.with_item([
      SurveyItem.content("#{@campaign_id}/welcome.png"),
      SurveyItem.info()
      |> SurveyItem.with_title(
        "Extensive research shows that people who set and track specific goals are 20 to 40% more likely to achieve them."
      )
      |> SurveyItem.with_title(
        "Once you set your goals, Driver's Seat will monitor your progress so you can see whether you're on track to hit your financial goals."
      )
    ])
    |> SurveySection.with_action([
      CampaignAction.new(:start, :next, "I want to set my earnings goals!"),
      CampaignAction.default_postpone_link(),
      CampaignAction.default_dismiss_link()
    ])
    |> SurveySection.hide_page_markers()
    |> SurveySection.hide_page_navigation()
  end

  defp get_section_goal_types do
    SurveySection.new(:goal_types)
    |> SurveySection.with_title("Types of Goals")
    |> SurveySection.with_item([
      SurveyItem.info()
      |> SurveyItem.with_description(
        "What are the time periods for which you would like to set goals?"
      ),
      SurveyItem.checkbox(:target_levels, :daily)
      |> SurveyItem.with_title("Daily Goals")
      |> SurveyItem.with_description("For example, I want to earn $200 each day that I work."),
      SurveyItem.checkbox(:target_levels, :weekly)
      |> SurveyItem.with_title("Weekly Goals")
      |> SurveyItem.with_description("For example, I want to earn $1,200 each week that I work."),
      SurveyItem.checkbox(:target_levels, :monthly)
      |> SurveyItem.with_title("Monthly Goals")
      |> SurveyItem.with_description("For example, I want to earn $4,000 each month that I work.")
    ])
    |> SurveySection.with_action([
      CampaignAction.default_postpone_link("Finish Later"),
      CampaignAction.default_dismiss_link("Quit")
    ])
  end

  defp get_section_daily_goals do
    SurveySection.new(:daily_goals)
    |> SurveySection.with_title("Daily Goals")
    |> SurveySection.with_description("How do you want to set your daily earnings goals?")
    |> SurveySection.depends_on_value(:target_levels, :daily)
    |> SurveySection.with_item([
      SurveyItem.radio_button(:daily_strategy, :same_all_days)
      |> SurveyItem.with_title("My goal is the same every day"),
      SurveyItem.currency(:daily_goal_all)
      |> SurveyItem.with_uom_right("/day")
      |> SurveyItem.with_indent_left(1)
      |> SurveyItem.depends_on_value(:daily_strategy, :same_all_days),
      SurveyItem.radio_button(:daily_strategy, :same_each_day_of_week)
      |> SurveyItem.with_title("My daily goal depends on the day of the week"),
      SurveyItem.currency(:daily_goal_mon)
      |> SurveyItem.with_label("Monday")
      |> SurveyItem.with_indent_left(1)
      |> SurveyItem.depends_on_value(:daily_strategy, :same_each_day_of_week),
      SurveyItem.currency(:daily_goal_tue)
      |> SurveyItem.with_label("Tuesday")
      |> SurveyItem.with_indent_left(1)
      |> SurveyItem.depends_on_value(:daily_strategy, :same_each_day_of_week),
      SurveyItem.currency(:daily_goal_wed)
      |> SurveyItem.with_label("Wednesday")
      |> SurveyItem.with_indent_left(1)
      |> SurveyItem.depends_on_value(:daily_strategy, :same_each_day_of_week),
      SurveyItem.currency(:daily_goal_thu)
      |> SurveyItem.with_label("Thursday")
      |> SurveyItem.with_indent_left(1)
      |> SurveyItem.depends_on_value(:daily_strategy, :same_each_day_of_week),
      SurveyItem.currency(:daily_goal_fri)
      |> SurveyItem.with_label("Friday")
      |> SurveyItem.with_indent_left(1)
      |> SurveyItem.depends_on_value(:daily_strategy, :same_each_day_of_week),
      SurveyItem.currency(:daily_goal_sat)
      |> SurveyItem.with_label("Saturday")
      |> SurveyItem.with_indent_left(1)
      |> SurveyItem.depends_on_value(:daily_strategy, :same_each_day_of_week),
      SurveyItem.currency(:daily_goal_sun)
      |> SurveyItem.with_label("Sunday")
      |> SurveyItem.with_indent_left(1)
      |> SurveyItem.depends_on_value(:daily_strategy, :same_each_day_of_week),
      SurveyItem.radio_button(:daily_strategy, :different_every_day)
      |> SurveyItem.with_title("Each day I set a different goal"),
      SurveyItem.currency(:daily_goal_diff)
      |> SurveyItem.with_uom_right("/day")
      |> SurveyItem.with_indent_left(1)
      |> SurveyItem.with_description(
        "What is your goal today, or for the last day that you worked?"
      )
      |> SurveyItem.depends_on_value(:daily_strategy, :different_every_day),
      SurveyItem.radio_button(:daily_strategy, :other)
      |> SurveyItem.with_title("I do something different"),
      SurveyItem.text(:daily_other_desc, :long_text)
      |> SurveyItem.with_indent_left(1)
      |> SurveyItem.with_description(
        "We're always interested in learning more about your work.  Please tell us more."
      )
      |> SurveyItem.depends_on_value(:daily_strategy, :other)
    ])
    |> SurveySection.validate_required(:daily_strategy)
    |> SurveySection.validate_required(:daily_other_desc)
    |> SurveySection.validate_min_value(:daily_goal_mon, 0)
    |> SurveySection.validate_min_value(:daily_goal_tue, 0)
    |> SurveySection.validate_min_value(:daily_goal_wed, 0)
    |> SurveySection.validate_min_value(:daily_goal_thu, 0)
    |> SurveySection.validate_min_value(:daily_goal_fri, 0)
    |> SurveySection.validate_min_value(:daily_goal_sat, 0)
    |> SurveySection.validate_min_value(:daily_goal_sun, 0)
    |> SurveySection.validate_min_value(:daily_goal_diff, 0)
    |> SurveySection.validate_required(:daily_goal_diff)
    |> SurveySection.validate_min_value(:daily_goal_all, 0)
    |> SurveySection.validate_required(:daily_goal_all)
    |> SurveySection.with_action([
      CampaignAction.default_postpone_link("Finish Later"),
      CampaignAction.default_dismiss_link("Quit")
    ])
  end

  defp get_section_weekly_goals do
    SurveySection.new(:weekly_goals)
    |> SurveySection.with_title("Weekly Goals")
    |> SurveySection.with_description("How do you want to set your weekly earnings goals?")
    |> SurveySection.depends_on_value(:target_levels, :weekly)
    |> SurveySection.with_item([
      SurveyItem.radio_button(:weekly_strategy, :same_all_weeks)
      |> SurveyItem.with_title("My goal is the same every week"),
      SurveyItem.currency(:weekly_goal_all)
      |> SurveyItem.with_uom_right("/week")
      |> SurveyItem.with_indent_left(1)
      |> SurveyItem.depends_on_value(:weekly_strategy, :same_all_weeks),
      SurveyItem.radio_button(:weekly_strategy, :different_every_week)
      |> SurveyItem.with_title("Each week I set a different goal"),
      SurveyItem.currency(:weekly_goal_diff)
      |> SurveyItem.with_uom_right("/week")
      |> SurveyItem.with_indent_left(1)
      |> SurveyItem.with_description(
        "What is your goal this week, or for the last week that you worked?"
      )
      |> SurveyItem.depends_on_value(:weekly_strategy, :different_every_week),
      SurveyItem.radio_button(:weekly_strategy, :other)
      |> SurveyItem.with_title("I do something different"),
      SurveyItem.text(:weekly_other_desc, :long_text)
      |> SurveyItem.with_indent_left(1)
      |> SurveyItem.with_description(
        "We're always interested in learning more about your work.  Please tell us more."
      )
      |> SurveyItem.depends_on_value(:weekly_strategy, :other)
    ])
    |> SurveySection.validate_required(:weekly_strategy)
    |> SurveySection.validate_required(:weekly_other_desc)
    |> SurveySection.validate_min_value(:weekly_goal_diff, 0)
    |> SurveySection.validate_required(:weekly_goal_diff)
    |> SurveySection.validate_min_value(:weekly_goal_all, 0)
    |> SurveySection.validate_required(:weekly_goal_all)
    |> SurveySection.with_action([
      CampaignAction.default_postpone_link("Finish Later"),
      CampaignAction.default_dismiss_link("Quit")
    ])
  end

  defp get_section_monthly_goals do
    SurveySection.new(:monthly_goals)
    |> SurveySection.with_title("Monthly Goals")
    |> SurveySection.with_description("How do you want to set your monthly earnings goals?")
    |> SurveySection.depends_on_value(:target_levels, :monthly)
    |> SurveySection.with_item([
      SurveyItem.radio_button(:monthly_strategy, :same_all_months)
      |> SurveyItem.with_title("My goal is the same every month"),
      SurveyItem.currency(:monthly_goal_all)
      |> SurveyItem.with_uom_right("/month")
      |> SurveyItem.with_indent_left(1)
      |> SurveyItem.depends_on_value(:monthly_strategy, :same_all_months),
      SurveyItem.radio_button(:monthly_strategy, :different_every_month)
      |> SurveyItem.with_title("Each month I set a different goal"),
      SurveyItem.currency(:monthly_goal_diff)
      |> SurveyItem.with_uom_right("/month")
      |> SurveyItem.with_indent_left(1)
      |> SurveyItem.with_description(
        "What is your goal this month, or for the last month that you worked?"
      )
      |> SurveyItem.depends_on_value(:monthly_strategy, :different_every_month),
      SurveyItem.radio_button(:monthly_strategy, :other)
      |> SurveyItem.with_title("I do something different"),
      SurveyItem.text(:monthly_other_desc, :long_text)
      |> SurveyItem.with_indent_left(1)
      |> SurveyItem.with_description(
        "We're always interested in learning more about your work.  Please tell us more."
      )
      |> SurveyItem.depends_on_value(:monthly_strategy, :other)
    ])
    |> SurveySection.validate_required(:monthly_strategy)
    |> SurveySection.validate_required(:monthly_other_desc)
    |> SurveySection.validate_min_value(:monthly_goal_diff, 0)
    |> SurveySection.validate_required(:monthly_goal_diff)
    |> SurveySection.validate_min_value(:monthly_goal_all, 0)
    |> SurveySection.validate_required(:monthly_goal_all)
    |> SurveySection.with_action([
      CampaignAction.default_postpone_link("Finish Later"),
      CampaignAction.default_dismiss_link("Quit")
    ])
  end

  defp get_section_other_strategies do
    SurveySection.new(:other_strategies)
    |> SurveySection.with_title("Other Strategies")
    |> SurveySection.with_description(
      "Do you use any of these other earning strategies when working?"
    )
    |> SurveySection.with_item([
      SurveyItem.checkbox(:other_strategies, :earnings_per_mile)
      |> SurveyItem.with_title("Earnings Per Mile")
      |> SurveyItem.with_description("I try to accept jobs above a certain $ amount per mile."),
      SurveyItem.currency(:earnings_per_mile_rate)
      |> SurveyItem.with_uom_right("/mile")
      |> SurveyItem.with_indent_left(1)
      |> SurveyItem.depends_on_value(:other_strategies, :earnings_per_mile),
      SurveyItem.checkbox(:other_strategies, :earnings_per_hour)
      |> SurveyItem.with_title("Hourly Pay")
      |> SurveyItem.with_description(
        "I try to accept jobs such that I make above a certain $ amount per hour."
      ),
      SurveyItem.currency(:earnings_per_hour_rate)
      |> SurveyItem.with_uom_right("/hour")
      |> SurveyItem.with_indent_left(1)
      |> SurveyItem.depends_on_value(:other_strategies, :earnings_per_hour),
      SurveyItem.checkbox(:other_strategies, :work_time)
      |> SurveyItem.with_title("Work Hours")
      |> SurveyItem.with_description("I limit my work hours within a daily or weekly timeframe."),
      SurveyItem.numeric(:work_time_hours_day)
      |> SurveyItem.with_indent_left(1)
      |> SurveyItem.with_scale(1)
      |> SurveyItem.with_label("daily")
      |> SurveyItem.with_uom_right("hours")
      |> SurveyItem.depends_on_value(:other_strategies, :work_time),
      SurveyItem.numeric(:work_time_hours_week)
      |> SurveyItem.with_indent_left(1)
      |> SurveyItem.with_scale(1)
      |> SurveyItem.with_label("weekly")
      |> SurveyItem.with_uom_right("hours")
      |> SurveyItem.depends_on_value(:other_strategies, :work_time)
    ])
    |> SurveySection.validate_required(:earnings_per_hour_rate)
    |> SurveySection.validate_min_value(:earnings_per_hour_rate, 0)
    |> SurveySection.validate_required(:earnings_per_mile_rate)
    |> SurveySection.validate_min_value(:earnings_per_mile_rate, 0)
    |> SurveySection.validate_min_value(:work_time_hours_week, 0)
    |> SurveySection.validate_max_value(:work_time_hours_week, 168)
    |> SurveySection.validate_min_value(:work_time_hours_day, 0)
    |> SurveySection.validate_max_value(:work_time_hours_day, 24)
    |> SurveySection.with_action([
      CampaignAction.default_postpone_link("Finish Later"),
      CampaignAction.default_dismiss_link("Quit")
    ])
  end

  defp get_section_finish do
    SurveySection.new(:finish)
    |> SurveySection.with_title("Thank You!")
    |> SurveySection.with_description(
      "Thank you for taking the time to tell us more about your goals."
    )
    |> SurveySection.with_item([
      SurveyItem.info()
      |> SurveyItem.with_description(
        "By Finishing this survey, we'll save your goals so that you can start monitoring them in the app."
      ),
      SurveyItem.text(:other_feedback, :long_text)
      |> SurveyItem.with_title("Is there anything else you'd like for us to know?")
    ])
    |> SurveySection.with_action(CampaignAction.new(:finish, :accept, "Finish"))
  end

  def one_time_migration do
    Marketing.query_campaign_participation()
    |> Marketing.query_filter_campaign(@campaign_id)
    |> Marketing.query_filter_accepted()
    |> Repo.all()
    |> Enum.each(fn survey ->
      if Repo.exists?(
           Goals.query_goals()
           |> Goals.query_goals_filter_user(survey.user_id)
         ) == false do
        user = Accounts.get_user!(survey.user_id)
        create_goals_from_survey_responses(user, Map.get(survey.additional_data, "data"))
      end
    end)
  end

  def migrate_all do
    surveys =
      Marketing.query_campaign_participation()
      |> Marketing.query_filter_campaign(@campaign_id)
      |> Marketing.query_filter_accepted()
      |> Repo.all()

    create_goals_from_survey_responses(surveys)
  end

  def migrate(user_id_or_ids) do
    surveys =
      Marketing.query_campaign_participation()
      |> Marketing.query_filter_user(user_id_or_ids)
      |> Marketing.query_filter_campaign(@campaign_id)
      |> Marketing.query_filter_accepted()
      |> Repo.all()

    create_goals_from_survey_responses(surveys)
  end

  defp create_goals_from_survey_responses(surveys) do
    List.wrap(surveys)
    |> Enum.map(fn survey ->
      if Repo.exists?(
           Goals.query_goals()
           |> Goals.query_goals().filter_user(survey.user_id)
         ) == false do
        user = Accounts.get_user!(survey.user_id)
        responses = Map.get(survey.additional_data, "data")

        case create_goals_from_survey_responses(user, responses) do
          :ok ->
            {:ok, survey.user_id}

          _ ->
            {:error, survey.user_id}
        end
      else
        {:not_converted, survey.user_id}
      end
    end)
  end

  defp create_goals_from_survey_responses(%User{} = _user, nil = _responses), do: :ok

  defp create_goals_from_survey_responses(%User{} = user, %{} = responses) do
    if Map.has_key?(responses, "daily_strategy"),
      do: create_daily_goals_from_responses(user, responses)

    if Map.has_key?(responses, "weekly_strategy"),
      do: create_weekly_goals_from_responses(user, responses)

    if Map.has_key?(responses, "monthly_strategy"),
      do: create_monthly_goals_from_responses(user, responses)

    :ok
  end

  defp create_daily_goals_from_responses(%User{} = user, %{} = responses) do
    today = DateTimeUtil.datetime_to_working_day(DateTime.utc_now(), User.timezone(user))
    {start_date, _end_date} = DateTimeUtil.get_time_window_for_date(today, :day)

    # depending on how they answered the day question, pick out overall value
    # or specific day answers
    sub_goals =
      if Map.get(responses, "daily_strategy") == "same_each_day_of_week" do
        %{
          "0" => to_cents(Map.get(responses, "daily_goal_sun")),
          "1" => to_cents(Map.get(responses, "daily_goal_mon")),
          "2" => to_cents(Map.get(responses, "daily_goal_tue")),
          "3" => to_cents(Map.get(responses, "daily_goal_wed")),
          "4" => to_cents(Map.get(responses, "daily_goal_thu")),
          "5" => to_cents(Map.get(responses, "daily_goal_fri")),
          "6" => to_cents(Map.get(responses, "daily_goal_sat"))
        }
      else
        %{
          "all" =>
            to_cents(
              Map.get(responses, "daily_goal_all") || Map.get(responses, "daily_goal_diff")
            )
        }
      end

    # filter out any nil or invalid values
    sub_goals =
      Map.filter(sub_goals, fn {_sub_frequency, amount} -> not is_nil(amount) and amount > 0 end)

    if Enum.any?(Map.keys(sub_goals)) do
      Goals.update_goals(user.id, :earnings, :day, start_date, sub_goals, nil)
    end
  end

  defp create_weekly_goals_from_responses(%User{} = user, %{} = responses) do
    today = DateTimeUtil.datetime_to_working_day(DateTime.utc_now(), User.timezone(user))
    {start_date, _end_date} = DateTimeUtil.get_time_window_for_date(today, :week)

    goal_amount =
      to_cents(Map.get(responses, "weekly_goal_all") || Map.get(responses, "weekly_goal_diff"))

    if goal_amount > 0 do
      Goals.update_goals(user.id, :earnings, :week, start_date, %{"all" => goal_amount}, nil)
    end
  end

  defp create_monthly_goals_from_responses(%User{} = user, %{} = responses) do
    today = DateTimeUtil.datetime_to_working_day(DateTime.utc_now(), User.timezone(user))
    {start_date, _end_date} = DateTimeUtil.get_time_window_for_date(today, :month)

    goal_amount =
      to_cents(Map.get(responses, "monthly_goal_all") || Map.get(responses, "monthly_goal_diff"))

    if goal_amount > 0 do
      Goals.update_goals(user.id, :earnings, :month, start_date, %{"all" => goal_amount}, nil)
    end
  end

  defp to_cents(nil), do: nil

  defp to_cents(value) when is_integer(value) do
    value * 100
  end

  defp to_cents(value) when is_float(value) do
    to_cents(Decimal.from_float(value))
  end

  defp to_cents(%Decimal{} = value) do
    (value * 100)
    |> Decimal.round(0)
    |> Decimal.to_integer()
  end

  defp to_cents(_val), do: nil
end
