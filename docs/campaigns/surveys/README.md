# Surveys

Surveys are campaigns that present and collect information from users.  They are divided into multiple pages (called sections).

|![1](images/example_1.png) | ![2](images/example_2.png)  | ![3](images/example_3.png)  |
|--                         |--                           |--                           |

## Declaring a Survey

Declare the Survey

```elixir
defmodule DriversSeatCoop.Marketing.Campaigns.Examples do

  alias DriversSeatCoop.Marketing.Survey
  alias DriversSeatCoop.Marketing.SurveyItem
  alias DriversSeatCoop.Marketing.SurveySection
  
  @example_survey :example_survey

  def survey do
    Survey.new(@example_survey)
    |> Survey.with_section()
  end
end
```

## Adding Sections/Pages to a Survey

### Section Types

#### Content Sections

A content presents external content for the page.  It is very similiar to [creating a Call To Action (CTA)](../call_to_action/README.md#identifying-the-content-required).

```elixir
defmodule DriversSeatCoop.Marketing.Campaigns.Examples do

  alias DriversSeatCoop.Marketing.Survey
  alias DriversSeatCoop.Marketing.SurveyItem
  alias DriversSeatCoop.Marketing.SurveySection
  
  @example_survey :example_survey

  def survey do
    Survey.new(@example_survey)
    |> Survey.with_section(
      SurveySection.new(:welcome)
      |> SurveySection.with_content_url("#{@example_survey}/index.html")
    )
  end
end
```

* [Externally Hosted Content](../call_to_action/README.md#externally-hosted-content)
* [Self Hosted Content](../call_to_action/README.md#self-hosted-content)
* [YouTube Video Content](../call_to_action/README.md#youtube-video-content)


#### Form Sections

Form sections usually collect information from the user, but can also present inforamtion to the user as well.

##### Adding Items to a Form Section

Items can be added individually, as a list, or dynamically based on a function that accepts a [CampaignState](../../../lib/dsc/marketing/campaign_state.ex) struct and returns a list of items.

```elixir
Survey.new(@example_survey)
|> Survey.with_section(
  SurveySection.new(:welcome)
  |> SurveySection.with_item( ... )
  |> SurveySection.with_item([ ... ] )
  |> SurveySection.with_item(fn %CampaignState{} = state -> ... end)
)
```


###### Informational

Add descriptive information to the user using an informational item.


| ![info](./images/survey_item_info.png)              |
|--                                                   |

```elixir
SurveySection.with_item(
  SurveyItem.info()
  |> SurveyItem.with_title("Here's How You Can help")
  |> SurveyItem.with_description("Getting Involved is easy and only takes a few moments of your time")
)
```

###### Images

Display an image to the user.

| ![image](./images/survey_item_image.png)            |
|--                                                   |

```elixir
section
|> SurveySection.with_item([
  SurveyItem.content("#{@example_survey}/welcome.png"),   #self hosted
])
```

* Find more information about [Self Hosted Content](../call_to_action/README.md#self-hosted-content).
* By default, the iamge will be sized to 100% width. Optionally use `with_indent` to make it smaller.

  | ![image indent](./images/survey_item_image_indent.png)      |
  |--                                                           |

  ```elixir
  section
  |> SurveySection.with_item(
    SurveyItem.content("#{@example_survey}/welcome.png")
    |> SurveyItem.with_indent(1)        # Idents the image on both the left and right (approx 40px)
    |> SurveyItem.with_indent_left(2)   # Idents the image on left only (approx 80px)
    |> SurveyItem.with_indent_right(2)  # Idents the image on right only (approx 80px)
  )
  ```

###### Text Box

Collect text information from the user.

| ![text short](./images/survey_item_text_short.png)  |
|--                                                   |

```elixir
section
|> SurveySection.with_item(
  SurveyItem.text(:first_name, :short_text)
  |> SurveyItem.with_hind("first name")
)
```

| ![text long](./images/survey_item_text_long.png)    |
|--                                                   |

```elixir
section
|> SurveySection.with_item(
  SurveyItem.text(:first_name, :long_text)
  |> SurveyItem.with_hint("Tell us what you like about Driver's Seat")
)
```

###### Radio Button

Present a set of mutually exclusive choices as radio buttons.  Items with the same field_id (:hours_per_week in this example) are mutually exclusive.

| ![radio](./images/survey_item_radio.png)            |
|--                                                   |

```elixir
section
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
```

###### Checkbox

Checkboxes can be used to present a single option

| ![checkbox single](./images/survey_item_checkbox_single.png)    |
|--                                                               |

```elixir
section
|> SurveySection.with_item(
  SurveyItem.checkbox(:sets_goals, :yes)      # If a value is not supplied, it defaults to TRUE
    |> SurveyItem.with_title("Do you set earning gols?")
    |> SurveyItem.with_description("Do you track your earnings and compare to a goal that you have set?")
)
```

Checkboxes can be used to present multiple options

| ![checkbox multi](./images/survey_item_checkbox_multiple.png)   |
|--                                                               |

```elixir
section
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
```

###### Numeric/Currency

Collect a numeric value

| ![numeric](./images/survey_item_numeric.png)  |
|--                                             |

```elixir

section
|> SurveySection.with_item(
  SurveyItem.numeric(:hours_per_month)
  |> SurveyItem.with_scale(0)                 # optional: whole number
  |> SurveyItem.with_label("monthly")         # optional
  |> SurveyItem.with_uom_right("hours")       # optional
)
```

Collect a currency value (dollars)

| ![currency](./images/survey_item_currency.png)  |
|--                                               |

```elixir
section
|> SurveySection.with_item(
  SurveyItem.currency(:monthly_goal)
  |> Surveyitem.with_scale(0)                 # optional: whole dollar
  |> SurveyItem.with_uom_right("/month")      # optional
)
```

###### Date

| ![date](./images/survey_item_date.png)        |
|--                                             |


```elixir
section
|> SurveySection.with_item(
  SurveyItem.date(:started_gig_work)
  |> SurveyItem.with_title("Start Date")
)
```

###### Segmented Buttons

| ![segment](./images/survey_item_segment_options.png)  |
|--                                                     |

```elixir
section
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
```

###### Inline Action

| ![action](./images/survey_item_action.png)   |
|--                                            |

```elixir
section
|> SurveySection.with_item(
  SurveyItem.action(
    CampaignAction.new(:download_data, :custom, "Download My Data")
  )
)
```

###### Spacer

Add vertical space between survey items

| ![spacer](./images/survey_item_spacer.png)   |
|--                                            |

```elixir
section
|> SurveySection.with_item([
  SurveyItem.info()
  |> SurveyItem.with_title("Signing up is easy and free")
  |> SurveyItem.with_description("Tell us a little about yourself"),
  SurveyItem.spacer(),
  SurveyItem.text(:fname)
  |> SurveyItem.with_hint("first name")
])
```


##### Item Dependencies

##### Section Validation

### Page Navigation

### Section Actions

Preview (link)


Sections
* id
* Header
  * Default Actions (Close, Help, Dismiss)
  * Title
  * Description
* Footer
  * Text
  * Action Buttons
  * Action Links  
* Content
  * Framed Content based section
  * Input/control based section
* Navigation
  * Page Markers
  * Page Navigation



Types of Inputs
* Text Box
* Radio Button
* Checkbox
* Numeric/Currency
* Date
* Segmented Buttons
* Action
* Content/Images


Other things

* Input Dependencies
* Section Dependencies
* Validations



## Example

