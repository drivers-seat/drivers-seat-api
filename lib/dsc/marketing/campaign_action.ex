defmodule DriversSeatCoop.Marketing.CampaignAction do
  alias DriversSeatCoop.Marketing.CampaignAction
  alias DriversSeatCoop.Marketing.CampaignHelpers
  alias DriversSeatCoop.Marketing.CampaignPopupMessage

  @one_day_minutes 60 * 24
  @reengage_default_seconds 0

  @enforce_keys [
    :id,
    :type,
    :text
  ]
  @derive Jason.Encoder
  defstruct [
    :id,
    :type,
    :text,
    :url,
    :postpone_minutes,
    :display_class,
    :action,
    :popup,
    :data,
    is_default: false,
    is_header: false,
    reengage_delay_seconds: @reengage_default_seconds
  ]

  def new(id, type, text)
      when is_atom(id) and
             type in [
               :accept,
               :dismiss,
               :postpone,
               :logout,
               :next,
               :prev,
               :custom,
               :detail,
               :help,
               :close
             ] do
    %CampaignAction{
      id: id,
      type: type,
      text: List.wrap(text)
    }
  end

  def with_url(%CampaignAction{} = action, url), do: Map.put(action, :url, url)

  def with_data(%CampaignAction{} = action, %{} = data), do: Map.put(action, :data, data)

  def with_reengage_delay(%CampaignAction{} = action, seconds)
      when is_integer(seconds) and seconds >= 0,
      do: Map.put(action, :reengage_delay_seconds, seconds)

  def with_postpone_minutes(%CampaignAction{} = action, minutes)
      when is_integer(minutes) and minutes > 0,
      do: Map.put(action, :postpone_minutes, minutes)

  def with_display_class(%CampaignAction{} = action, class_or_classes),
    do: CampaignHelpers.with_display_class(action, class_or_classes)

  def as_header_tool(%CampaignAction{} = action, val \\ true) when is_boolean(val),
    do: Map.put(action, :is_header, val)

  def as_link(%CampaignAction{} = action, val \\ true) when is_boolean(val),
    do: Map.put(action, :is_default, val)

  def with_popup(%CampaignAction{} = action, %CampaignPopupMessage{} = popup),
    do: Map.put(action, :popup, popup)

  def default_postpone_link(text \\ "Maybe Later") do
    new(:default, :postpone, text)
    |> as_link()
    |> with_postpone_minutes(@one_day_minutes)
  end

  def default_postpone_tool(postpone_minutes \\ @one_day_minutes) do
    new(:default, :postpone, "X")
    |> as_header_tool()
    |> with_postpone_minutes(postpone_minutes)
  end

  def default_dismiss_link(text \\ "No Thanks") do
    new(:default, :dismiss, text)
    |> as_link()
  end

  def default_close(text \\ "Close") do
    new(:default, :close, text)
  end

  def default_close_link(text \\ "Close") do
    default_close(text)
    |> as_link()
  end

  def default_close_tool do
    new(:close, :close, "X")
    |> as_header_tool()
  end

  def default_dismiss_tool do
    new(:dismiss, :dismiss, "X")
    |> as_header_tool()
  end

  def default_help(button_text, message_text) do
    new(:help, :help, button_text)
    |> with_data(%{
      message_text: message_text
    })
  end

  def default_help_link(message_text) do
    default_help("Help", message_text)
    |> as_link()
  end

  def default_help_tool(message_text) do
    default_help("?", message_text)
    |> as_header_tool()
  end
end
