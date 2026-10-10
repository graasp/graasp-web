%{
title: "Introduction",
description: "Who the developer documentation is for and the tools you need to contribute",
order: 0
}

---

This is the documentation of the Graasp digital education platform targeted at developers.

> #### Target Audience {: .info}
>
>
> This documentation is targeted at people writing code or who want to be involved with code or architecture of the platform.
>
> For the end-user documentation, tutorials and reference, please go to [the User docs](/docs)
>

This documentation focuses on:

- the setup and installation of the platform on your machine
- the guidelines and protocols to participate and contribute in the development of Graasp
- a technical description of the architecture and features of Graasp

## Prerequisites {: #pre-requisites}

This documentation assumes that you are familiar with the command line.
We will guide you and tell you which commands to run, but it is best if you can understand what they will do.

If you need a complete refresher on how to do web development you should have a look at [the Odin Project](https://www.theodinproject.com/)

## What you'll need

Here we list the tools that you should have installed in order to make your development work easier.

### Required {: #required}

- A modern browser: Arc, Chrome, Firefox, Safari or others will work, choose based on your personal preference (it is recommended to have at least 2 installed on your machine in cases where you need to debug browser compatibility issues)
- A recent version of [Node.js](https://nodejs.org/en/download) (22 or above):
  - We recommend to use [`volta`, a node version manager](https://volta.sh/)
  - You can also use [`nvm`, an older node version manager](https://github.com/nvm-sh/nvm)
- A code editor:
  - We recommend [VSCode](https://code.visualstudio.com) as our main supported development IDE, because we will be using [devcontainers](https://code.visualstudio.com/docs/devcontainers/containers) to create our development environment for the backend.
  - You can also use IntelliJ WebStorm, SublimeText, or even vi, vim, nvim, emacs etc...
- [Docker Desktop](https://www.docker.com/products/docker-desktop/): to run containers
  > #### Tip {: .info}
  >
  > You do not need to login to Docker.

### Nice to have {: #nice-to-have}

These are a few tools that we find nice to have when developing.
Feel free to install them and try them out if you think they add value.

- An API client that allows you to make requests to the backend:
  - We recommend [Bruno](https://www.usebruno.com/): an API client similar to Postman or Insomnia.
  - [Postman](https://www.postman.com/downloads): lets you send API requests with a GUI
- [Starship](https://starship.rs/): a utility to improve your terminal prompt (git branch, node version etc...)
- The [fish shell](https://fishshell.com/) as an alternative to zsh or bash
- `gh`, the [github command line](https://cli.github.com), allows you to interact with github features from the cli, clone, create PRs, view workflow runs, list issues etc.

### For people on macOS

For users on macOS we have a list of tools that we think will make your life easier:

- [Rectangle.app](https://rectangleapp.com/) a window manager that allows you to re-organize your window layout with the keyboard. It also supports dragging and snapping to edges of the screen. Very light weight, try it out by pressing `ctrl + alt + left arrow`, your current window should now take half the horizontal space on the left. There is a pro version available. IMO the base version is already enough, but if you think you will benefit from the upgrade and want to support the work of the developer, maybe consider buying the pro version.
- [brew](https://brew.sh/) the missing package manager for macOS. You might already have installed it, but if not, it is a good tool to have.

## Tools and practices {: #tools}

We use:

- [Typescript](https://www.typescriptlang.org/)
- [Linters](https://eslint.org/)
- [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)
- Test suits:
  - [Cypress](https://www.cypress.io/): E2E tests
  - [Playwright](https://playwright.dev/): E2E tests
  - [Vitest](https://vitest.dev/): unit tests
- [Storybook](https://storybook.js.org/) for component library design, prototyping and documentation
- [Semantic versioning](https://semver.org/)
