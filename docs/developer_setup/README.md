# Developer Setup

1. **Clone this repo locally**
2. **Install Prerequisites**
   * [Homebrew](https://brew.sh/)
   * [NodeJS](https://nodejs.org/en/download/package-manager#alternatives-2)

      ```shell
      brew install node
      ```

   * [ASDF multiple runtime version manager](https://asdf-vm.com/)<br>
     Install ASDF and ensure that it starts up when opening new shell windows (zsh)

      ```shell
      brew install asdf
      echo -e '\n. /opt/homebrew/opt/asdf/libexec/asdf.sh' >> ~/.zshrc
      ```

   * PostgreSQL and PostGIS <br/>

      ```shell
      brew install postgresql
      brew install postgis
      ```

      ensure that you have a `postgres` user with password `postgres`
      <br/>

3. **Install Elixir and Erlang** <br/>
   Open a new shell, especially after installing Node and ASDF.

   ```shell
   asdf plugin add erlang
   asdf plugin add elixir
   asdf install erlang 25.3.2.7
   asdf install elixir 1.14.0-otp-25
   asdf global erlang 25.3.2.7
   asdf global elixir 1.14.0-otp-25
   ```
  
4. **Get Dependencies** <br/>
   Open a new shell.  You may be asked to confirm installation (select Y)

   ```shell
   mix deps.get
   ```

5. **Create empty API database and perform migrations**
  
   ```shell
   mix ecto.create
   mix ecto.migrate
   ```

6. **Seed Data** <br/>
  
    * Create the initial admin user and an initial terms of service.  You will need to do this prior to connecting with the mobile app as it requires users a terms of service to be available to the user.

      ```shell
      mix run priv/repo/seeds.exs
      ```

    * TODO: Loading Geographic shapes (region_county, region_state, region_metro_area, region_postal_code)
    <br/>
  
7. **Start the local Web Server** <br/>

   ```shell
   mix phx.server
   ```

   * API: http://localhost:4000
   * Admin Site: http://localhost:4000/_admin

## Running Unit Tests

Prior to running unit tests, you should have Postgresql installed and your postgres user configured.  Running the unit tests will create a test database `drivers_seat_coop_test`.

```shell
mix test
```


## Code Layout, Quality, Linting

The following will standardize code formatting an perform various code quality checks.  Ideally your CI/CD pipeline will verify that this has been done as part of pull request verification.

```shell
mix format
mix credo --strict --all
```

## Background/Scheduled Tasks (Oban)

   We use [Oban](https://hexdocs.pm/oban/Oban.html) to perform background tasks.

   In development, environment Variable `OBAN_QUEUES` will determines which queues will be active and how many workers will service each queue.  Since many background processes interact with external services, most times we do not want them to run.

   For example:

   ```shell
   export OBAN_QUEUES="update_timespans_for_user:1 update_timespans_for_user_workday:2 goals:2"
   ```
