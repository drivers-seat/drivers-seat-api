# Campaigns

Campaigns support the presentation and interaction of dynamic content in the mobile app.  Because they are defined in the API layer (in code), campaigns:

* May be tailored for the calling user and/or device being used.
* May be released and/or modified without the need for a mobile app release.
* Take affect immediately

___

* [Campaign Types](#types-of-campaigns)
* [Qualifying Criteria/Audience Filtering](#qualifying-criteria-for-a-campaign)
* [Campaign Categories](#adding-categories-to-a-campaign)


## Types of Campaigns

* [Call To Action](#calls-to-action-ctas)
* [Surveys](#surveys)
* [Checklists](#checklists)

### [Calls to Action (CTAs)](./call_to_action/README.md)

A call to action presents information to the user a a single view of hosted web content.  Users may be presented various actions.

|![CTA](./call_to_action/images/example.png)  |
|---                                          |

### [Surveys](./surveys/README.md)

A survey is an interactive workflow divided into one or many pages (known as sections).  Each section presents and can/usually collects information from the user.  Information collected from the user is stored in the `additiona_info` column of table `campaign_participants`.

  |![1](./surveys/images/example_1.png)  |![2](./surveys/images/example_2.png)  |![3](./surveys/images/example_3.png)|
  |-- |-- |--|
  
### Checklists

A checklist is a list of tasks/items with status information.  Unlike surveys and CTAs, checklists appear as cards that are embedded within other application pages.

  |![1](./checklists/images/example_landing_page.png)  |![2](./checklists/images/example_checklist.png)  |
  |-- |-- |
  
## Qualifying Criteria for a Campaign

Qualifying criteria allows the filtering of campaigns for specific users, devices, and or conditions.  

### Caller App Version

Filter campaigns based on the version of the mobile app making the call.

Example: This CTA will only be available to callers on a version < 4.0.0.

```elixir
CallToAction.new(:upgrade_for_better_mileage_tracking)
|> Campaign.include_app_version("< 4.0.0")
```

```elixir
CallToAction.new(:upgrade_for_better_mileage_tracking)
|> Campaign.exclude_app_version(">= 4.0.0")
```

### Custom Criteria using a function

Provide a function that accepts a [CampaignState](../../lib/dsc/marketing/campaign_state.ex) struct and returns TRUE if the caller should have access to the campaign.

Example: This survey will become available 5-days after the user has created their account if they have not successfully set up a gig-account.

```elixir
defmodule DriversSeatCoop.Marketing.Campaigns.Examples do
  alias DriversSeatCoop.GigAccounts
  alias DriversSeatCoop.Marketing.Campaign
  alias DriversSeatCoop.Marketing.Survey
  alias DriversSeatCoop.Repo

  @five_days_seconds 60 * 60 * 24 * 5

  def survey do
    Survey.new(:connect_gig_accts)
      |> Campaign.is_qualified(fn %CampaignState{} = state ->
        # it has been less that 5 days
        if NaiveDateTime.diff(NaiveDateTime.utc_now(), state.user.inserted_at) < @five_days_seconds do
          false
        else
          # user has not already connected a gig account
          not (GigAccounts.query()
               |> GigAccounts.query_filter_user(state.user.id)
               |> GigAccounts.query_filter_is_connected()
               |> Repo.exists?())
        end
      end)
  end
end
```


## Adding Categories to a Campaign

Campaigns can be assigned one or many categories which determines where they will be surfaced in the application.

```elixir
CallToAction.new(:upgrade_for_better_mileage_tracking)
|> Campaign.with_category([
  :interrupt, 
  :info
])
```

Categorization can also be dynamic.  Provide a function that accepts a [CampaignState](../../lib/dsc/marketing/campaign_state.ex) struct and returns one or many categories.



```elixir
# This campaign is presented in full-screen mode (because of the :interrupt category).  
# If the user accepts the campaign, it will also add a preview card to their dashboard
# as well (because of the :dashboard_info category)

CallToAction.new(:upgrade_for_better_mileage_tracking)
|> Campaign.with_category(fn %CampaignState{} = state ->

  result = [:interupt]

  if is_nil(state.participant.accepted_on),
    do: result ++ [:dashboard_info],
    else: result

end)

```


### `:interrupt` Category

Campaigns that are categorized as `:interrupt` will interrupt the user's workflow when ALL of the following conditions are met

* User meets the [qualification criteria](#qualifying-criteria-for-a-campaign).
* User has not [accepted](./campaign_actions/README.md/#accept) or [dismissed](./campaign_actions/README.md/#dismiss) the campaign.
* Campaign is not currently [postponed](./campaign_actions/README.md/#postpone-for-duration) for the user.
