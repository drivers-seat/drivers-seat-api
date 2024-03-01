# Calls to Action (CTAs)

A call to action presents information to the user a a single view of hosted web content.  Users may respond to the CTA using various actions.  They should be considered one-way communication.

![](./images/CTA_components.png)

## Declaring the campaign  (Required)

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

## Identifying the hosted content (Required)

### Self-hosted Content

When the url is relative, it is assumed that the content is hosted on the same server as the API, managed in source control, and deployed with each release.

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

Hosted assets (like html, css, images, fonts, js) should be placed within the `/priv/static/campaigns` folder and managed as part of source control.

* **Asset names are case sensitive** and need to match the filename of the asset.  `example_cta/example.html` is NOT the same as `example_cta/Example.html` OR `example_CTA/example.html`
<br/>

* **Consider having a common campaign.css file** and add relative references to it from within the html files for each campaign.  That will make style changes a bit easier.
<br/>

* **Consider having a folder Structure Convention** such as `/priv/static/campaigns/<<CAMPAIGN_ID>>` for the assets for each campaign.  The CTA defined above would follow this folder structure.
<br/>

  ```text
  .
  └── priv
      └── static
          └── campaigns
              ├── campaigns.css
              └── example_cta
                  ├── example_cta.html
                  ├── example_cta.css
                  ├── example_cta_image1.png
                  └── example_cta_image2.png
  ```

* **Browsing to campaign assets directly** Self-hosted assets are browseable.  During development for the example above, `http://localhost:4000/web/campaigns/example_cta.html` should present the content of the CTA.
<br/>
* **The [endpoint.ex](/lib/dsc_web/endpoint.ex) file** is respoinsible for mapping inbound url requests to static files.

### Externally Hosted Content

CTA content may also be hosted elsewhere, which may be helpful if it is managed outside of this app, or if it is large, making it difficult to manage in source control.  To access externally hosted content, use fully qualified URLs for the resources.

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

## Adding Header and Footer Text (Optional)

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

## Adding Campaign Actions

Campaign Actions define how a user will interact with the campaign.

### Toolbar Help

| ![close](./images/default_help.png)  |
|----                                           |


### Toolbar Dismiss or Close
There are two options for closing a campaign.
| ![close](./images/default_close_dismiss.png)  |
|----                                           |


#### Close
Closing the CTA closes the screen in the UI, but the campaign is still available for the user at a later date.  Closing a CTA is often used when the user navigates to the CTA, but it does not interrupt their workflow.  For example, a user may navigate to a CTA from a preview card on their landing page.  They would go back to their landing page by closing the CTA.


#### Dismiss
Dismissing the CTA is the equivalent to deleting it for the user, preventing them from seeing the campaign again. Dismissing a CTA is often used for interrupt campaigns which interrupt the user's workflow.


* **Dismiss** - Prevents the campaign from being visible to the user again.
* **Close** - Prevents the campaign from being visible to the user again.

```elixir
    cta
    |> CallToAction.with_action(CampaignAction.default_close_tool())

    cta
    |> CallToAction.with_action(CampaignAction.default_dismiss_tool())

    cta
    |> CallToAction.with_action(
      CampaignAction.default_help_tool("Pre populate the help message with this text")
    )

```



### Actions Buttons
### Action Links

```elixir
cta =
  CallToAction.with_action(cta,
    CampaignAction.new(:join, :accept, "Join our community!")
    |> CampaignAction.
  )
```

## Associate to Categories


```elixir
cta = Campaign.with_category(cta, :interrupt)  
```
