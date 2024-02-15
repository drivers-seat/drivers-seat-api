defmodule DriversSeatCoop.Marketing.CampaignPreview do
  alias DriversSeatCoop.Marketing.CampaignHelpers
  alias DriversSeatCoop.Marketing.CampaignState

  def new do
    %{
      type: :preview,
      title: [],
      description: [],
      actions: [],
      content_url: nil,
      image_url_left: nil,
      image_url_right: nil,
      chart_top: nil,
      chart_bottom: nil,
      display_class: nil
    }
  end

  def with_title(item, value_or_values),
    do: Map.put(item, :title, List.wrap(item.title) ++ List.wrap(value_or_values))

  def with_description(item, value_or_values),
    do: Map.put(item, :description, List.wrap(item.description) ++ List.wrap(value_or_values))

  def with_action(preview, action_or_actions),
    do: Map.put(preview, :actions, List.wrap(preview.actions) ++ List.wrap(action_or_actions))

  def with_display_class(preview, class_or_classes),
    do: CampaignHelpers.with_display_class(preview, class_or_classes)

  def with_content_url(preview, url),
    do: Map.put(preview, :content_url, URI.to_string(CampaignHelpers.get_resource_uri(url)))

  def with_left_image_url(preview, url),
    do: Map.put(preview, :image_url_left, URI.to_string(CampaignHelpers.get_resource_uri(url)))

  def with_right_image_url(preview, url),
    do: Map.put(preview, :image_url_right, URI.to_string(CampaignHelpers.get_resource_uri(url)))

  def with_top_chart(preview, %{type: :chart} = chart), do: Map.put(preview, :chart_top, chart)

  def with_bottom_chart(preview, %{type: :chart} = chart),
    do: Map.put(preview, :chart_bottom, chart)

  def get_config(
        %{
          type: :preview
        } = preview,
        %CampaignState{}
      ),
      do: preview
end
