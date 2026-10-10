%{
title: "Backend",
description: "Architecture of the Graasp backend services",
order: 2
}

---

The backend of Graasp (also called "core" or "api") is the combination of services that run on the server.

## General concepts {: #general-concepts}

The backend is implemented in Typescript using [Fastify](https://www.fastify.io/) for the web framework and [Slonik](https://github.com/gajus/slonik) for SQL query-building. The database(s) uses [PostgreSQL](https://www.postgresql.org/).
