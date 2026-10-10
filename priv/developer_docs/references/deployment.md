%{
title: "Deployment",
description: "How the Graasp platform is packaged and deployed",
order: 1
}

---

In this reference document we discuss the deployment of the Graasp platform.
By deployment we understand the process of packaging the source code and making it available world wide to users.
For this we rely on our infrastructure, which is the definition of the resources and their arrangement which allow us to make the platform available to clients.

## Infrastructure as code

We manage the infrastructure with code. This practice is called "infrastructure as code" or IaC for short.
It allows to define the components of the deployed infrastructure through code making the management easier for users already familiar with these concepts.

The official instance of Graasp at [graasp.org](https://graasp.org) is hosted on AWS.
AWS is the cloud provider making the computing resources available to run the Graasp platform.
The IaC uses [Terraform](https://developer.hashicorp.com/terraform) for its declarative and idempotent nature, [the CDK for terraform (CDKTF)](https://developer.hashicorp.com/terraform/cdktf) for programmatic access and [the prebuilt AWS Provider for CDKTF](https://github.com/cdktf/cdktf-provider-aws) to manage AWS-specific resources.
This makes the infrastructure specific to hosting with the services provided by AWS.
In order to be independent of the cloud provider, the infrastructure should use abstractions that are available on all cloud providers.
In our case the development cost to implement such cloud-agnostic architecture was not worth it.

> #### Note {: .info}
>
> We do provide alternative ways of running Graasp on non-AWS infrastructure.
> See [the docker compose file for standalone installation](https://github.com/graasp/graasp/blob/main/docker/compose.yml).
> Be warned that it will require so work on your side and that technical knowledge
> is required.

The infrastructure code can be found in [the Graasp infrastructure repository on GitHub](https://github.com/graasp/graasp-infrastructure).

## Infrastructure diagram

Clients can hit the following public endpoints:

- Client App (graasp.org) -> SPA hosted on S3 and served by Cloudfront
- Graasp Core API (api.graasp.org) -> NodeJS application running in an Elastic Container Service (ECS)
- Library App (library.graasp.org) -> NextJS application running in ECS
- Etherpad API (etherpad.graasp.org) -> External service running in ECS
- Umami API (umami.graasp.org) -> External service running in ECS

The services running in ECS are behind a Elastic Load-Balancer (ELB) which distributes requests to the correct containers based on the hostname in the request.

Etherpad and Umami have a connection to the Relational Database Service (RDS) cluster and they manage their own database inside the graasp instance.

The core API has connections to:

- Iframely: External service providing website embeds running in ECS
- NudeNet: External service providing inappropriate content detection running in ECS (same container as core API)
- Redis: for its realtime key value capabilities running in ECS
- Meilisearch: External service providing indexation and search on published content running in ECS

A worker container is running in ECS and has a connection to:

- RDS Database: getting data for requests
- Meilisearch: indexing cotent periodically
- Redis: for getting the jobs from the queues

## Infrastructure states

The infrastructure can be in 4 different states.

The normal state in `running`. In this state all necessary services are running
and the app is fully available.

The `restricted` state enables a maintenance mode that redirects traffic to
the maintenance page unless it provides some special headers. This mode is
useful when you want to start a maintenance operation and need to drain users
from the services. It is also used to ensure correct operation after some
work has been done. Developers using an extension that adds the special headers
on every request are able to test the platform while normal users still see the
maintenance redirection.

The `db-only` state stops all core services other than the web analytics service
`umami` and the database. It is used to perform migrations. We require the
backend server to be down to ensure migrations are performed without conflicts
from users interacting with the platform. This process does not allow rolling
deployments and requires a service interruption. We think that at our scale these
trade-offs are acceptable as they allow us to reduce the complexity of deploying
a new version of the platform. In the `db-only` state a single-use task containing
the migration code is run.

The `stopped` state stops all services and puts the platform in a "deep-sleep".
We use it to spare costs on our development and staging environments when they
are not in use.

## Anatomy of a deployment

A deployment usually follows these steps:

1. Initial state, normal operation.
2. Apply `restricted`: redirect users to Maintenance, drain connections.
3. Apply `db-only`: run migrations, stop all graasp services.
4. Apply `restricted`: run graasp services, accept only connections from devs.
5. Apply `running`: final state, normal operation with new code.
