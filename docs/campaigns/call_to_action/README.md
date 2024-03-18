# Calls to Action (CTAs)

A call to action presents information to the user a a single view of hosted web content.  Users may respond to the CTA using various actions.  CTAs are considered one-way communication.

![Call To Action (CTA)](./images/CTA_components.png)

* [Declaring a CTA](#declaring-the-cta-required) - required
* [Identify Hosted Content](#identifying-the-content-required) - required
* [Adding Header and Footer Text](#adding-header-and-footer-text-optional) - optional
* [Adding Actions](#adding-actions) - optional


## Declaring the CTA (Required)

Declare the CTA

```elixir
defmodule DriversSeatCoop.Marketing.Campaigns.Examples do
  
  alias DriversSeatCoop.Marketing.CallToAction

  # using a module attribute will be helpful as you declare content
  @example_cta :example_cta

  def cta do
    CallToAction.new(@example_cta)
  end
end
```

## Identifying the content (Required)

### Self-hosted Content

A relative URL indicates that the content is hosted on the same server as the API, managed in source control, and deployed with each release.

```elixir
defmodule DriversSeatCoop.Marketing.Campaigns.Examples do
  
  alias DriversSeatCoop.Marketing.CallToAction

  @example_cta :example_cta

  def cta do
    CallToAction.new(@example_cta)
    |> CallToAction.with_content_url("#{@example_cta}/example.html")
  end
end
```

Self-hosted assets (like html, css, images, fonts, js) are placed within the `/priv/static/campaigns` folder and managed as part of source control.

* **Asset and folder names are case sensitive** and need to match the filename of the asset.  `example_cta/example.html` is NOT the same as `example_cta/Example.html` OR `example_CTA/example.html`

* **Consider having a common campaign.css file** and add relative references to it from within the html files for each campaign.  That will make style changes a bit easier.

* **Consider having a folder structure convention** such as `/priv/static/campaigns/<<CAMPAIGN_ID>>/` for the assets for each campaign.  The CTA defined above would follow this folder structure.

  ```text
  .
  └── priv
      └── static
          └── campaigns
              ├── campaigns.css
              └── example_cta
                  ├── example.html
                  ├── example.css
                  ├── example_image1.png
                  └── example_image2.png
  ```

* **Browsing to campaign assets directly** Self-hosted assets are browseable.  During development for the example above, `http://localhost:4000/web/campaigns/example_cta/example.html` should present the content of the CTA.

* **The [endpoint.ex](/lib/dsc_web/endpoint.ex) file** is respoinsible for mapping inbound url requests to static files.

### Externally Hosted Content

CTA content may also be hosted elsewhere, which may be helpful when the content is managed outside of the app, or if the assets are large and  difficult to manage in source control.  

To access externally hosted content, use fully qualified URLs for the resources.

```elixir
defmodule DriversSeatCoop.Marketing.Campaigns.Examples do
  
  alias DriversSeatCoop.Marketing.CallToAction

  @example_cta :example_cta

  def cta do
    CallToAction.new(@example_cta)
    |> CallToAction.with_content_url("https://blog.driversseat.co/campaigns/whatsapp-community/intro-whatsapp-community")
  end
end
```

#### YouTube Video Content

CTA content may be a Youtube hosted video.  The URL must be in the form below using the embed syntax.

```elixir
defmodule DriversSeatCoop.Marketing.Campaigns.Examples do
  
  alias DriversSeatCoop.Marketing.CallToAction

  @example_cta :example_cta

  def cta do
    CallToAction.new(@example_cta)
    |> CallToAction.with_content_url("https://www.youtube.com/embed/1zGlYNS2qGk")
  end
end
```

### Query Parmeters applied to URLs

The following query parameters are appended to the URL making them available to the page being requested.

* App Version running on the device (`version`)
* User ID (`user`)
* First Name (`first_name`)
* Last Name (`last_name`)
* Device Language (`language`)
* Device Platform (`platform`)

For example:

```text
http://localhost:4000/web/campaigns/welcome_to_wao_drivers_seat/page1.html?version=1.0.0&user=1&first_name=J&last_name=F&language=EN&platform=WEB&device=4b03200e-5e75-4460-a891-aa71db979468
```



## Adding Header and Footer Text (Optional)

| ![header](./images/header.png)  | ![footer](./images/footer.png)    |
|---                              |---                                |
|                                 |                                   |

### Single Line

```elixir
cta
|> DriversSeatCoop.Marketing.CallToAction.with_header("Single Line Header")
|> DriversSeatCoop.Marketing.CallToAction.with_footer("Single Line Footer")
```

### Multi-Line

```elixir
cta
|> DriversSeatCoop.Marketing.CallToAction.with_header([
    "Main Title (displayed in bold)",
    "Sub Title 1 (smaller and not bold)"
])
|> DriversSeatCoop.Marketing.CallToAction.with_footer([
    "Main footer",
    "Footer Line 2"
])
```

### Dynamic Content

A function accepting a [CampaignState](/lib/dsc/marketing/campaign_state.ex) struct may also be used.  CampaignState provides access to information about the calling user, their device, and the calling user's interaction with this campaign.

```elixir
alias DriversSeatCoop.Marketing.CallToAction
alias DriversSeatCoop.Marketing.CampaignState

cta
|> CallToAction.with_header(fn %CampaignState{} = state ->
  "Hi, #{state.user.first_name}"
end)
|> CallToAction.with_header(fn %CampaignState{} = state ->
  "You're using an #{state.device.device_platform} device"
end)
```

## Adding Actions

[Campaign Actions](../campaign_actions/README.md) define how a user may interact with the campaign.  Here are some examples, see [Campaign Actions](../campaign_actions/README.md) for more in-depth information.

Add an accept action presented as a button.

```elixir
cta
|> CallToAction.with_action(
  CampaignAction.new(:add_goals, :accept, "Let's Get Started")
)
```

Add a postpone (for 90 minutes) action as a link.

```elixir
cta
|> CallToAction.with_action(
  CampaignAction.new(:remind_later, :postpone, "Maybe Later")
  |> CampaignAction.with_postpone_minutes(90)
  |> CampaignAction.as_link()
)
```

Add a dismiss action presented as a Link.

```elixir
cta
|> CallToAction.with_action(
  CampaignAction.new(:no_thanks, :dismiss, "No Thanks")
  |> CampaignAction.as_link()
)
```

Add a dismiss action presented as header tool close button.

```elixir
cta
|> CallToAction.with_action(
  CampaignAction.new(:no_thanks, :dismiss, "X")
  |> CampaignAction.as_header_tool()
)
```

Add a help action as a link.

```elixir
cta
|> CallToAction.with_action(
  CampaignAction.new(:question, :help, "I have a question")
  |> CampaignAction.with_data(%{
    message_text: "[ Tell us how we can help you with this campaign ]"
  })
  |> CampaignAction.as_link()
)
```

Add a help action as a header tool help icon.

```elixir
cta
|> CallToAction.with_action(
  CampaignAction.new(:question, :help, "I have a question")
  |> CampaignAction.with_data(%{
    message_text: "[ Tell us how we can help you with this campaign ]"
  })
  |> CampaignAction.as_header_tool()
)
```

### Adding actions conditionally

Add an action conditionally to a CTA by supplying a function that, given `%CampaignState{}` evaluates to TRUE or FALSE

This example only allows the user to pospone a campaign once.  If the user has NOT previously dismissed the campaign, add the postpone action.

```elixir
cta
|> CallToAction.with_conditional_action(
  # function returning t/f
  fn %CampaignState{} = state ->
    is_nil(state.participant.postponed_until)
  end,
  # action or actions if true
  CampaignAction.new(:remind_later, :postpone, "Maybe Later")
  |> CampaignAction.with_postpone_minutes(90)
  |> CampaignAction.as_link()
)
```

### Adding actions dynamically

Add actions dynamically to a CTA by supplying a function that, given `%CampaignState{}` returns a list of `%CampaignAction{}`.


This example only allows the go to blog action (as button) if the user's account is at least 5 days old.

```elixir
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
```