defmodule DriversSeatCoop.ArgyleTestClient do
  @behaviour DriversSeatCoop.ArgyleClient

  def init do
    Agent.start(fn -> %{} end, name: __MODULE__)
  end

  def should_see(call, resp) do
    pid = self()

    Agent.update(__MODULE__, fn a ->
      a = Map.put_new(a, pid, %{})

      Map.update!(a, pid, fn b ->
        Map.put(b, call, {resp, 0})
      end)
    end)
  end

  def saw_everything? do
    pid = self()

    calls =
      Agent.get(__MODULE__, fn a ->
        Map.get(a, pid, %{})
      end)
      |> Enum.filter(fn {_, {_, n}} ->
        n == 0
      end)

    if calls == [] do
      true
    else
      calls
    end
  end

  def cleanup do
    pid = self()

    Agent.update(__MODULE__, fn a ->
      Map.delete(a, pid)
    end)
  end

  @impl true
  def get_linked_accounts(argyle_user_id) do
    call({:get_linked_accounts, [argyle_user_id, %{}]})
  end

  @impl true
  def create do
    call({:create, [%{}, %{}]})
  end

  @impl true
  def update_user_token(argyle_user_id) do
    call({:update_user_token, [argyle_user_id, %{}]})
  end

  @impl true
  def delete(a_user) do
    call({:delete, [a_user, %{}]})
  end

  @impl true
  def vehicles(a_user, opts \\ %{}) do
    call({:vehicles, [a_user, opts]})
  end

  @impl true
  def profiles(a_user, opts \\ %{}) do
    call({:profiles, [a_user, opts]})
  end

  defp call(call) do
    pid = self()

    resp =
      Agent.get_and_update(__MODULE__, fn global_state ->
        Map.get_and_update(global_state, pid, fn process_state ->
          handle_call(process_state, call)
        end)
      end)

    case resp do
      nil -> {:error, "nil resp", inspect(call)}
      {resp, _} -> {:ok, resp}
    end
  end

  defp handle_call(nil, call) do
    handle_call(%{}, call)
  end

  defp handle_call(process_state, call) do
    Map.get_and_update(process_state, call, fn c ->
      if is_nil(c) do
        :pop
      else
        {resp, n} = c
        {c, {resp, n + 1}}
      end
    end)
  end
end
