defmodule DriversSeatCoop.ArgyleClient do
  @callback get_linked_accounts(String.t()) :: {:ok, list(map())} | {:error, term()}
  @callback create() :: {:ok, map()} | {:error, term()}
  @callback update_user_token(String.t()) :: {:ok, map()} | {:error, term()}
  @callback delete(String.t()) :: {:ok, list(map())} | {:error, term()}
  @callback profiles(String.t(), list()) :: {:ok, list(map())} | {:error, term()}
  @callback vehicles(String.t(), list()) :: {:ok, list(map())} | {:error, term()}
end
