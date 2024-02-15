defmodule DriversSeatCoopWeb.UserValidator do
  def update(params) do
    # TODO: Remove when version 3.0.0 is no longer supported.
    # Some versions of the App (through v3.0.0) send dates as RFC like strings "Mon Dec 05 2022 13:30:05 GMT-0800"
    # which will not parse and report 422-Unprocessable entity.  Since this is a privacy field, we need to make it
    # backwards compatible.  Parse the value and convert it.
    params =
      if Map.has_key?(params, "opted_out_of_data_sale_at") do
        case Timex.parse(
               Map.get(params, "opted_out_of_data_sale_at"),
               "%a %b %d %Y %H:%M:%S %Z",
               :strftime
             ) do
          {:ok, dtm} ->
            Map.put(params, "opted_out_of_data_sale_at", DateTime.shift_zone!(dtm, "Etc/UTC"))

          _ ->
            params
        end
      else
        params
      end

    {:ok, params}
  end
end
