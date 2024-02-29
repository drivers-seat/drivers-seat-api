# Campaigns

Campaigns support the presentation and interaction of dynamic content in the mobile app.  Because they are defined in the API layer (in code), campaigns:

* May be tailored for the calling user and/or device being used.
* May be released and/or modified without the need for a mobile app release.
* Take affect immediately

## Types of Campaigns

### Calls to Action (CTAs)

A call to action presents information to the user a a single view of hosted web content.  Users may be presented various actions.

|![CTA](./call_to_action/images/example.png)  |
|---                                          |

### Surveys

A survey is an interactive workflow divided into one or many pages (sections).  Each section presents and (usually) collects information from the user.  Information collected from the user is stored in the database.

  |![1](./surveys/images/example_1.png)  |![2](./surveys/images/example_2.png)  |![3](./surveys/images/example_3.png)
  |-- |-- |--
  
### Checklists

A checklist is a list of tasks/items with status information.  Unlike surveys and CTAs, checklists appear as cards that are embedded within other application pages.

  |![1](./checklists/images/example_landing_page.png)  |![2](./checklists/images//example_checklist.png)  |
  |-- |--
  








---------------------------







  

## All Campaigns have

* **ID** <br/>
  <br/>

* **Qualification Criteria** <br/>
  * Include or Exclude Mobile App Versions
  * Custom Function
    <br/>

* **Status**  <br/>
  * Not Started
  * Presented
  * Postponed (until)
  * Dismissed
  * Accepted
  <br/>

* **Saved State** (survey only) <br>



## Campaign Preview Cards

* Customizing the Landing Page



## Static Content

## Database Queries

## Mixpanel Integration

## How to Create a Campaign

## Examples