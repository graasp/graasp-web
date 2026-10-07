# Graasp web

[![gitlocalized german](https://gitlocalize.com/repo/10639/de/badge.svg)](https://gitlocalize.com/repo/10639/de?utm_source=badge)
[![gitlocalized french](https://gitlocalize.com/repo/10639/fr/badge.svg)](https://gitlocalize.com/repo/10639/fr?utm_source=badge)
[![gitlocalized italian](https://gitlocalize.com/repo/10639/it/badge.svg)](https://gitlocalize.com/repo/10639/it?utm_source=badge)
[![gitlocalized spanish](https://gitlocalize.com/repo/10639/es/badge.svg)](https://gitlocalize.com/repo/10639/es?utm_source=badge)

This is the codebase for the Graasp frontend and administration interface.
It is written in [Elixir](https://elixir-lang.org/) using [the Phoenix web framework](https://phoenixframework.org).

The admin platform enables administrators to:

- manage publications
- send messages to target audiences
- manage interactive applications
- perform operational tasks (re-indexation, ...)
- explore analytics data

## Required tools

This project uses [mise](https://mise.jdx.dev/) for tasks and tool versions.
Install mise from [the instructions](https://mise.jdx.dev/getting-started.html)

Install all dependencies with (installs `elixir` and `erlang`):

```sh
mise i
```

As of writing this, the following versions are used:

- elixir: 1.19.5
- erlang: 28 (OTP 28)

<details>
    <summary>Installing Elixir with brew (not recommended)</summary>

### Elixir

You will need Elixir and OTP installed.
On MacOS simply run: `brew install elixir`
For installation instructions refer to the [elixir installation guide](https://hexdocs.pm/phoenix/1.8.0/installation.html)

You can test you installation by running `elixir -v`. It should output something like:

```txt
Erlang/OTP 28 [erts-16.0.2] [source] [64-bit] [smp:8:8] [ds:8:8:10] [async-threads:1] [jit] [dtrace]

Elixir 1.18.4 (compiled with Erlang/OTP 27)
```

Also install `elixir-ls` (one of) the Elixir Language server. With brew:

```sh
brew install elixir-ls
```

</details>

### Poppler

The chatbot app extracts the text of uploaded PDFs with `pdftotext`, from [poppler](https://poppler.freedesktop.org/).
On MacOS: `brew install poppler`. On Debian/Ubuntu: `apt-get install poppler-utils`.

### PostgreSQL

The admin platform uses the same database as the core platform.

We recommend that you use the database provided by the devcontainer for the graasp/core project when running the admin.

For tests or if you only need to access admin's related data, you will be fine using a local postgres instance for example via a docker container, or with an app such as [Postgres.app](https://postgresapp.com/) on MacOS.

#### Devcontainer database

You want to use all features of graasp and have an install of the core project running in the devcontainer.
In this case, you should find a user `graasper` owning the `graasp` database accessible on `localhost:5432` from the host machine.
Ensure this postgres is running when running the admin.

You should ensure that the migrations from the core project are applied. After that run the admin-specific migrations with: `mix ecto.migrate`.

#### Local database docker

In case you want to run the admin standalone, you can use the following command to start a postgresql server in a docker container.

```sh
docker run -d -p 5432:5432 \
              -e POSTGRES_USER=graasper \
              -e POSTGRES_DB=graasp \
              -e POSTGRES_PASSWORD="graasper" \
              --name postgres postgres:17.5-alpine
```

#### Local database (gui client)

You can also use a graphical client like [Postgres.app](https://postgresapp.com/) on MacOS.

## Getting Started

0. Ensure you have Elixir installed (`elixir -v` should show you the version)
1. Install project dependencies with: `mix deps.get`
2. Compile the project with: `mix compile`
3. Run the migrations with: `mix ecto.migrate`
4. Create a `.env.sh` file with the following content. Use the values you get from configuring garage in the core project:
   ```sh
   # .env.sh
   export AWS_ACCESS_KEY_ID=GK3b...
   export AWS_SECRET_ACCESS_KEY=a03cf77e181...
   export AWS_DEFAULT_REGION=garage
   export UMAMI_USERNAME=some_username
   export UMAMI_PASSWORD=a_strong_password
   export UMAMI_WEBSITE_ID=a_website_id_you_create_in_umami
   ```
   You will need to source this file in your shell before starting the server:
   ```sh
   source .env.sh
   ```
5. Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`
   Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Testing

For tests you should have a database available on `localhost:5433` with user `postgres` and password `postgres`.
To run the tests: `mix test`
After some failed tests re-run only failed tests with: `mix test --failed`
To debug failed tests: `iex -S mix test --failed --breakpoints --trace`

## Deployment

The application is deployed on AWS using ECS. The deployment process is handled by the graasp/infrastructure repository.
It is in charge of registering the service and starting the tasks with the proper environment variables.
This repo simply builds the docker images and pushes them to the private ECR registry and requests a service update so that the new image is used by the service.

Please checkout [the setup docs](./docs/setup.md) for more information on how to bootstrap a server to deploy your app in production.

### Deploying with docker locally

It is possible to run this application with docker compose in a "local" environment (i.e. not a cloud-provider like AWS).
Below you will find all options that you can use to customize the application so that it runs without issues in docker compose:

```yaml
admin:
  image: <image-name> # or public.ecr.aws/graasp/admin:v0.10.5
  hostname: admin
  environment:
    # This depends on where your database is, this example uses a database in the same docker compose exposed as `db` host with graasper credentials
    DATABASE_URL: postgres://graasper:graasper@db:5432/graasp
    # The host that the application is running on, this is normally `graasp.org` but in local we use `localhost`
    PHX_HOST: localhost
    # The port that the application is running on (for the container network)
    PORT: 4000
    # The public port that the application is running on, can be different from the PORT if behind a reverse proxy
    PUBLIC_PORT: 4000
    # The protocol to use, default to `https`, in this case we want to force it to HTTP because we do not have a certificate
    PROTOCOL: http
    # The secret key base, generate one with: `mix phx.gen.secret`
    SECRET_KEY_BASE: <secet value>
    # The release cookie allows multiple instances of the app to communicate, genreate it via: `mix phx.gen.secret`
    RELEASE_COOKIE: <secret value>
    # The name of the files item bucket, refer to the core documentation on how to create the buckets in garage (s3-compatible storage)
    FILE_ITEMS_BUCKET_NAME: file-items
    # The name of the H5P bucket, same as for the file bucket, refer to the docs on how to create the bucket in garage
    H5P_CONTENT_BUCKET_NAME: h5p-items
    # AWS access key and secret, when using garage
    AWS_ACCESS_KEY_ID: <secert value>
    AWS_SECRET_ACCESS_KEY: <secret value>
    # When using garage, set the region to `garage`
    AWS_REGION: garage
    # Override the protocol to use HTTP (in local we do not have HTTPS)
    AWS_S3_SCHEME: http://
    # The S3 host set for garage, override the aws default
    AWS_S3_HOST: s3.garage.localhost
    # The port that the s3 api responds to for garage
    AWS_S3_PORT: 3900
    # Use path style (default for aws s3 is to put bucket_name as sub-domain)
    AWS_S3_USE_PATH_STYLE: true
    # Override the Mailer adapter from AWS SES to use a simple SMTP server (either a local mailcatcher or external SMTP server)
    MAILER_CONNECTION: smtp://docker:docker@mailer:1025
  ports:
    - "4000:4000"
  links:
    # This is necessary so that the s3 garage domain resolves to the container in the docker network
    - garage:s3.garage.localhost
  depends_on:
    - core
  restart: unless-stopped
```

## Translations

This project uses [gettext](https://hexdocs.pm/gettext/Gettext.html) for translations.
Gettext works by extracting strings from the code and storing them in a `.pot` file. This file is the template and should not be modified directly.
Active translations are stored in `.po` files. These are the files that translators need to work on.

Gettext allows to group translations by domain. This is useful to separate translations for different parts of the application. The `default` domain is used when nothing is specified.

Gettext allows to define multiple backends. This allows to separate translations for different concerns. In our application, we have the application UI and the email templates. Since the user's interface can be in a different language than the email template, we use two backends: `AdminWeb.Gettext` for the UI and `AdminWeb.EmailTemplates.Gettext` for the email templates. This allows us to set a locale for each backend independently.

The UI translations are stored in `priv/gettext/*`. The email template translations are stored in `priv/gettext_email_templates/*`.

The next sections describe how to work with translations. A commodity mix alias is provided to make it easier to update and merge translations: `mix i18n`.

### Extracting strings from code

To extract translation strings from the code, run `mix gettext.extract`.

The message strings should be literal strings solvable at compile time.

### Translating strings

Translated message strings are stored in `.po` files. The language specific translation files are stored in `admin/priv/gettext/<lang>/LC_MESSAGES/<domain>.po`.
For example, the `en` (English) translations for the `default` domain are stored in `admin/priv/gettext/en/LC_MESSAGES/default.po`.
To sync the translations, run `mix gettext.merge priv/gettext` and `mix gettext.merge priv/gettext_email_templates`.

### Adding new languages

To support a new language, create a new folder in `priv/gettext` then run `mix gettext.merge priv/gettext`.
Do the same for `priv/gettext_email_templates`.

### Correctly extracting strings from MJML-enabled templates

Email templates under `lib/admin_web/email_templates/templates_html` are MJML-enabled. In order for gettext to correctly extract the translation strings at compile time we need to:

- include `<% use Gettext, backend: AdminWeb.EmailTemplates.Gettext %>` at the top of the template file.
- use the `gettext` macro with literal strings in the template body

This should allow to correctly extract the translation strings at compile time. It can be verified by adding a new string to a template and running `mix gettext.extract` then `mix gettext.merge priv/gettext_email_templates`.

## Common commands

Checkout [the memento](./docs/memento.md) for an overview of helpful commands for managing the project (deployment and development).

## Troubleshooting and general help

### Cleaning artifacts after making a release

If you made a release locally it is possible that you end-up with a lot of files in the `priv/static/` folder.

Before committing, run: `mix phx.digest.clean --all` to clean them.
