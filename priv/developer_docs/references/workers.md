%{
title: "Queues and Workers",
description: "Background jobs offloaded to queues and workers",
order: 3
}

---

Graasp sometimes performs high-computation operations that can be resource-intensive and time-consuming. If executed on the main thread alongside the core application, these operations would block the main process, negatively impacting performance and responsiveness of Graasp.

To prevent such issues, these heavy processes are offloaded to background workers through a job queueing system. The current offloaded jobs are:

- Re-index meilisearch (every week at 3AM)
- Export a folder as raw content
- Export a folder as a graasp archive (TODO)
- Export actions of an item (TODO)
- Copy a tree hierarchy (TODO)
- Clear a recycle bin (TODO)

## Implementation

We use [BullMQ](https://bullmq.io/), a robust and modern job queue library for Node.js built on Redis, to manage asynchronous task execution. The above tasks can be started by adding a corresponding job inside a BullMQ queue. Each queue is dedicated to a specific category of jobs.

## DevOps

### Local Development

In local environments, the worker service is bundled into the same Docker container as the core Graasp application. It starts alongside the main server, making development setup straightforward and self-contained. If the source code is updated, both the core server and the worker service are rebuilt and re-started, which allows a smoother development workflow.

A dashboard is available at `http:localhost:3000/ui` to monitor the queues and their jobs.

### Production Environment

In production, the architecture is more modular. The worker service runs as an independent container, separated from the core Graasp server. This separation allows workers to scale independently and utilize dedicated CPU and memory resources. Additionally, running workers as isolated services makes it easier to monitor, restart, replicate, and update them without affecting the main application.
