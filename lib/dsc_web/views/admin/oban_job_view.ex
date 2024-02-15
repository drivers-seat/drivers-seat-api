defmodule DriversSeatCoopWeb.Admin.ObanJobView do
  use DriversSeatCoopWeb, :view

  import Torch.TableView
  import Torch.FilterView

  def json_preview(data) do
    Jason.encode!(data)
  end

  def json_pretty(data) do
    Jason.encode!(data, pretty: true)
  end
end
