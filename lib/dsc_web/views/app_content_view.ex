defmodule DriversSeatCoopWeb.AppContentView do
  use DriversSeatCoopWeb, :view

  def render("campaign_styles.scss", _) do
    ~s(
    <style>
        
      </style>
    )
  end

  def render("onboarding_status.html", %{
        items: onboarding_items
      }) do
    Enum.map_join(onboarding_items, "\n", fn {title, url, status} ->
      title =
        case status do
          :complete ->
            "☒ #{title}"

          :warning ->
            "⚠️ #{title}"

          _ ->
            "□ #{title}"
        end

      if is_nil(url),
        do: "<div title>#{title}</div>",
        else: ~s(<div title><a onclick="#{url}">#{title}</a><div>)
    end)
  end
end
