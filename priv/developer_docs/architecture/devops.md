%{
title: "DevOps",
description: "How Graasp is operated and deployed",
order: 3
}

---

In this section we describe how the Graasp cloud deployment is handled by going through the steps needed to deploy a new version.

## Context

The Graasp infrastructure is deployed on the AWS cloud platform. AWS is used as a hosting provider, making compute and storage available to their customers who are responsible for configuring and using the resources they pay for.

The Graasp source code is hosted on GitHub.
We develop the Graasp platform as an open-source project.
To get involved, [contact us on GitHub](https://github.com/graasp)!

The orchestration and automation is carried out by GitHub Actions (CI runners).
These allow us to run workflows that perform code checking, build and deployment to our cloud infrastructure.

The infrastructure is defined with Typescript via terraform using the terraform CDKTF library.
We do "Infrastructure as Code" (IaC).
IaC allows us to manage our infrastructure the same way we manage our source code.
We use version control and can the same workflows as with code allowing us to review, merge and build our infrastructure as if it was just another code project.

## Deployment state

The infrastructure can be in any of the following states:

- **running**: all services are running, the platform is available under normal conditions
- **restricted**: services are running, but they are not available to the normal user, they see a maintenance screen
- **db-only**: no services are running, only the database is available and a migration task is launched when transitioning to this state
- **stopped**: nothing is running all services are at 0 and the db is temporarily stopped (max 7 days then AWS starts it again)

## Continuous integration (CI)

Github Actions used to build, test and deploy apps

Github Pages used to host storybook (design system)

## Infrastructure

You can read the full [deployment reference](deployment) for more information on how the infrastructure is deployed and maintained.
Deploys on AWS

## Workers

Since some features in Graasp involve heavy computational logic (e.g., exporting actions), these processes are submitted to queues. A separate service is responsible for handling workers that listen to these queues.

In a local environment, the worker service runs within the same container as the core server and starts alongside it. A dashboard is available to monitor the queues and their jobs at `http:localhost:3000/ui`.

In production, the worker service is launched as a separate task, allowing it to use its own CPU and resources independently.

For more details, read more about [Queues and Workers in our references](workers).
