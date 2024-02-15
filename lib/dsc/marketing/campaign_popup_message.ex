defmodule DriversSeatCoop.Marketing.CampaignPopupMessage do
  alias DriversSeatCoop.Marketing.CampaignHelpers
  alias DriversSeatCoop.Marketing.CampaignPopupMessage

  @derive Jason.Encoder
  defstruct title: nil,
            description: nil,
            link_actions: [],
            display_class: nil

  def new do
    %CampaignPopupMessage{}
  end

  def with_title(%CampaignPopupMessage{} = item, value_or_values),
    do: Map.put(item, :title, List.wrap(item.title) ++ List.wrap(value_or_values))

  def with_description(%CampaignPopupMessage{} = item, value_or_values),
    do: Map.put(item, :description, List.wrap(item.description) ++ List.wrap(value_or_values))

  def with_action(%CampaignPopupMessage{} = item, id, text, url)
      when is_atom(id) and not is_nil(text) and not is_nil(url),
      do:
        Map.put(
          item,
          :link_actions,
          List.wrap(item.link_actions) ++
            [
              %{
                id: id,
                text: text,
                is_close: false,
                url: url
              }
            ]
        )

  def with_close_action(%CampaignPopupMessage{} = item, id, text)
      when is_atom(id) and not is_nil(text),
      do:
        Map.put(
          item,
          :link_actions,
          List.wrap(item.link_actions) ++
            [
              %{
                id: id,
                text: text,
                is_close: true,
                url: nil
              }
            ]
        )

  def with_display_class(%CampaignPopupMessage{} = item, class_or_classes),
    do: CampaignHelpers.with_display_class(item, class_or_classes)
end
