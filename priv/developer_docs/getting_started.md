%{
title: "Getting Started",
description: "A guide to get you set-up contributing code to the Graasp platform",
order: 1,
tags: ["coding", "developer"]
}

---

In this page we guide you through setting up a working local development environment.
By the end of this guide you should have a working version of the Graasp platform running on your computer.

> #### Only for full platform development {: .info}
>
> This guide helps you set up your local development environment for the Graasp platform.
>
> If you only need to develop a **Graasp app**, you don't need the full setup.
> You can head over to [the Graasp App Development section](intro).

> #### Prerequisites {: .warning}
>
> We will assume that you have a UNIX compatible machine at your disposal (Mac, Linux or Windows with WSL). All instructions should work independently of the environment. If you encounter problems, please [open an issue](https://github.com/graasp/graasp-web/issues/new).

## Requirements {: #requirements}

If not done already please install these required tools

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (if using Mac or Windows), on Linux you should be good with installing the docker package from your distribution's package manager.
- [Node](https://nodejs.org/en/download) version 24 or above. Most projects will define a `mise.toml` file where the correct node version will be installed automatically. For projects where that is not the case, you can install the correct version using [`volta`](https://volta.sh/) or [`nvm`](https://nvm.sh/).
- `git` for version control operations

## Node package managers

Refer to [node package managers](package_managers) for instructions on how to install node package managers for the project.

## Backend installation {: #backend}

### Getting the source code

Go to the [Graasp backend repo](https://github.com/graasp/graasp-api) and clone it locally.

> #### With the Github CLI {: .info}
>
> If you are using the [`Github CLI`](https://cli.github.com/) simply `gh repo clone graasp/graasp`.
> We recommend using the Github CLI as it helps with interacting with GitHub trough the terminal if this is your thing. (We think it is is faster for a lot of things, but you are welcome to use a GUI (Graphical user interface) if you prefer.)

### Opening dev containers {: #dev-containers}

1. Open the Docker Desktop app.

   > #### Docker Desktop should run in the background {: .info}
   >
   > This app should run in the background. You do not need to have it automatically start when you open your session. It simply needs to run when you want to use the backend to code.

2. Open the repo in VSCode. Make sure the ["Dev Containers" extension](https://code.visualstudio.com/docs/devcontainers/tutorial#_install-the-extension) is downloaded and enabled.

3. Open the folder in the dev-container by using the command palette `cmd`+`shift`+`P` (or `ctrl` instead of `cmd` on non-macOS systems), and typing **Open Folder in Container**.

4. You should now wait for VSCode to pull the containers and initialize the development environnement. You will know that the process if finished once the window says: `workspace [Dev Container: Node.js & PostgreSQL @desktop-linux]` and no more loaders are present.

If you encounter an error at this stage, make sure that the Docker Desktop app is open. If you encounter an issue with the definition of the dev-container not willing to start you can open an issue in the [graasp backend repository on GitHub](https://github.com/graasp/graasp-api/issues/new) or send an email to [the graasp developers](mailto:dev@graasp.org). We try to offer support as best as we can.

### Installing dependencies {: #dependencies}

After the containers are up and running execute `yarn` (you can also run `yarn install` which is the same) in the dev-container terminal (in VSCode) to install the backend dependencies.

> #### This may take some time {: .info}
>
> The install command will take some time to run the first time. This is a good time to take a small break, enjoy a :coffee: or a :tea:.

> #### Troubleshooting {: .warning}
>
> If the command exits with an error you might have to allocate more resources to the docker container.
>
> For this go to the Docker Desktop app settings and under "Resources" allocate up to 8GB of RAM (depending on your system resources you might want to allocate less) and up to 4CPUs.

### Add environment variables {: #env-variables}

Open [the configuration in the README.md](https://github.com/graasp/graasp-api#configuration).
Copy it to a new file named `.env.development` in the root of your backend folder.

Most of the configuration values have already been set for you in the readme, but you will need to generate some secret keys for your application.

#### Secret keys {: #secret-keys}

Open the `.env.development` file and look for places that ask for `<secret-key>`.
The first one should be `SECURE_SESSION_SECRET_KEY`.
To generate a secret you can simply run:

```sh
npx @fastify/secure-session > secret-key && node -e "let fs=require('fs'),file=path.join(__dirname, 'secret-key');console.log(fs.readFileSync(file).toString('hex'));fs.unlinkSync(file)"
```

Replace the `<secret-key>` placeholder with the output of the command (a string of numbers).
Repeat the process until you have generated all necessary keys. You can search for `<secret-key>` in the file in order to located them (you can use `cmd+f` to search in the file).

> #### Google RECAPTCHA key {: .info}
>
> This part should be optional, but if you want to be as close as possible to the how the app works in the real world, it is recommended to set it up.
>
> See detailed information in the [section below](#recaptcha-key)

> #### OpenAI API Key {: .info #open-ai-key}
>
> Also optional, this part allows you to have access to LLMs from OpenAI in the Graasp Apps running in your local environnement.
>
> This requires an OpenAI account and a payment method. See [OpenAI documentation](https://openai.com/pricing).

### Setting up the Database

#### Ensuring the DB is boostrapped

The database should have been automatically boostrapped by the init.sql script mounted in the db container.
You can verify it is the case by connecting to the database and checking the `graasp` dtatabase is available:
In a terminal in the connected vscode devcontainer run:

```sh
psql -h db -U docker -d docker
```

Enter the password for the docker user: `docker`
You should now be at the psql prompt and see: `docker=> `
You can list the databases available with `\l` (backslash l)
You should see at least the 4 required databases for graasp:

- graasp
- etherpad
- test
- umami

You can connect to the graasp databse with `\c graasp`
The should change to: `graasp=> `
You can list the tables in the database with: `\d`
Currently there should be no tables (this is normal we will create them in the next step).

#### Creating the tables with the migration script

To create the tables and have our database up-to-date with the current state of the application we will need to run the migrations for the application.

In the terminal of the devcontainer in vscode:

```sh
yarn migration:run
```

This should run for some time and then finish with:

```txt
[✓] migrations applied successfully!
```

You can verify that the tables are now available.

Open a psql prompt with:

```sh
psql -h db -U graasper -d graasp
```

Enter the graasper password: `graasper`

List the tables of the graasp database: `\d`.
You should see around 50 tables.

### Launching the backend server {: #running-backend}

We should be all set. Run `yarn watch` in the VSCode terminal to start the backend server.

Wait a moment, for the server to build, will see the `[Node] [nodemon] restarting due to changes...` text printed to the console. Wait to see:

```text
[Node] {"level":30,"time":1709056074491,"pid":33974,"hostname":"4ca0ec878e31","msg":"Server listening at http://0.0.0.0:3000"}
```

If everything went well, opening [`http://localhost:3000/status`](http://localhost:3000/status) in your browser should greet you with "OK".

If you face an error, check [the Troubleshooting page](troubleshooting) to see if your issue is mentioned there.

> #### Issues resolving `localstack` domain locally {: .info}
>
> Your browser might not be able to resolve the `localstack` domain when uploading and viewing files. To use localstack with the Docker installation, it is necessary to edit your `/etc/hosts` with the following line `127.0.0.1 localstack`. This is necessary because the backend creates signed urls with the localstack container hostname. Without changing the hosts, the development machine cannot resolve the `http://localstack` hostname.
>
> **Do not forget to reboot your computer for these changes to take effect**

## Frontend installation {: #frontend}

> #### This section needs to be updated {: .warning}
>
> You should refer to the [Readme of the Graasp Web project](https://github.com/graasp/graasp-web#readme)

<details>
  <summary>Click to show outdated instructions</summary>

With the backend server running we will now need to clone, install and run the client applications.

### All the Clients

There are 2 frontend applications in Graasp:

- [Client](https://github.com/graasp/client): the core frontend application
- [Library](https://github.com/graasp/graasp-library): service to publish content

For each one:

- Clone the repo
- Open the repo in VSCode
- Install the dependencies, `pnpm i` for client and `yarn` for library.
- Create the necessary `.env.development` file in each project. Look for instructions and examples about this in the Readme of each project
- Start each project with `pnpm dev` (client) and `yarn start` (library)

### Generating reCaptcha keys for auth and the backend {: #recaptcha-key}

You will likely need to generate your own RECAPTCHA key in order for the client frontend to be able to send login/register requests to the backend. For this you will need a Google account.

- Go to [the RECAPTCHA admin Console](https://www.google.com/recaptcha/admin)
- Log into your google account
- [Create a new site](https://www.google.com/recaptcha/admin/create)
- Give it a name that you will remember later (i.e. `graasp local dev`)
- Use version 3
- Add the `localhost` domain

Once that is done, you should get 2 keys, a **Site key** and a **Secret key**.
The **Site key** should go into the `.env.development` file from the Client project under the `VITE_RECAPTCHA_SITE_KEY` variable.
The **Secret key** should go into the `.env.development` file from the backend project under the `<google-recaptcha-key>` placeholder.

> #### Do not share these keys with anyone {: .error}
>
> Do not share these keys with anyone. Do not push them to version control (git). If you loose them, you can always re-generate new keys.

## Making sure everything works {: #everything-together}

With the default setup you should have the following:

- Backend Server running on `http://localhost:3000`
- Client frontend running on `http://localhost:3114`
- Library frontend running on `http://localhost:3005`

To start using the platform, open `http://localhost:3114`

Since your backend server is all fresh and new, there are no user accounts yet. Register using any email you want (`toto@test.lol`, `test@google.com`) it does not need to be a real email (it should only look like one). No emails will leave your computer, everything will be local and handled by the `mailcatcher` container.

> #### If you have trouble registering {: .warning}
>
> Check that you have generated reCaptcha keys and that they are set inside your .env\* files (in the backend and in the client).

Once you have registered with an email, open `http://localhost:1080`. There you should see a webUI called `MailCatcher`, it is a mail interface where you should see the registration email from graasp. Click on the link and continue the procedure.

Try to upload a file. If you get an error make sure that you have set `S3_FILE_ITEM_PLUGIN` to true in the backend env file. If you change the value, kill the server (`ctrl`+`C`) and relaunch it for the environmental changes to take effect.
If you are able to upload but there is an error when you want to display the file, make sure you have done the trick for the `localstack` domain described in [the running the backend tip section](#running-backend).

> #### Data persistence {: .note}
>
> If you restart you computer, the stored files will disappear, but not their item record. This is expected as localstack (the solution we use to fake s3 storage) does not provide persistence without buying the "pro" license.

</details>

## Conclusion {: #conclusion}

If you are still here, congratulations, you have successfully installed a development version of Graasp. You can take a well deserved break with a coffee or tea.

We are looking forward to hear from you on our open-source projects, collaborating and building engaging platforms.

If you have any comments regarding this guide, please open an issue on GitHub, or send us a mail: contact [at] graasp [dot] org
