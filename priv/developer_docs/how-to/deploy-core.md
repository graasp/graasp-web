%{
title: "Deploy a new backend version",
description: "This descibes the process of deploying a new core version of the application"
}

---

This guide shows you **how to deploy a new backend version**.
We will provide steps for applying migrations.

1. Create a release for the changes you want to deploy. The backend uses release-please for this purpose. If you have releasable changes you will find an open pull-request with a title similar to: `chore(main): release 1.66.0`. If you do not find an open pull-request refer to [the troubleshooting guide for release-please](release-please)
   1. Review the changes in the PR.
   1. Merge the PR. The release please action will now push a new tag and create a GitHub release. For more information on how release please works see [the Release-please reference](release-please).
1. Deploy the maintenance to block traffic to the services.
   1. Run the [`Apply infrastructure on env`](https://github.com/graasp/graasp-infrastructure/actions/workflows/infrastructure-deploy-env.yml) workflow inside the Graasp infra repo. Select the environment you want to target (dev, stage, prod) and choose the `restricted` state.
   1. If deploying to stage or prod, validate the deployment.
   1. Once deployment is done, ensure the services are not accessible by going to the url. It should display the maintenance page.
   1. Observe your realtime traffic using Umami and the Cloudfront dashboard in AWS. Once you are sure all traffic has been drained, you can proceed.
1. Create a snapshot of the database. This will be useful if you encounter errors in the migrations and need to revert to a previous version.
   1. From the Aurora and RDS panel in AWS you will be able to "Take a snapshot".
   1. Name the snapshot so you can find it later. Describing the purpose of the migration is a good idea. `pre-drizzle-migration` for example.
   1. Wait for the snapshot to complete. This can take up to 15min.
1. Deploy the migration.
   1. Run the [`Apply Migration`](https://github.com/graasp/graasp-infrastructure/actions/workflows/apply-migration.yml) workflow in the graasp infrastructure repo. Select the environment that you want to use (dev, stage, prod) and the name of the version you want to deploy. If you deployed with release-please, it is something like: `v1.66.0`, if you created a version manually, use the label you provided `drizzle-init` for example.
   1. If deploying to stage or prod, validate the deployment.
   1. Wait for the CI to be done. It will look for the logs of the migration task and exist once the migration is done. You can observe the tasks inside the cluster in AWS to see what is going on. Refer to [the migration reference for more information on how migrations are performed](devops).
   1. Wait for the load on the database to settle. Some vacuuming operations may take place after a large migration.
1. Deploy the new backend version.
   1. Run the [`Deploy new core version`](https://github.com/graasp/graasp-infrastructure/actions/workflows/deploy-core-version.yml) workflow from the graasp infrastructure repo. Choose the right environment and select the `restricted` state to deploy with maintenance enabled.
   1. If deploying to stage or prod, validate the deployment.
   1. Wait for the workflow to complete.
1. Test the deployment is successful. Using the maintenance headers you can access the application and test that everything is working as expected.
   1. If you see issues, you can patch them and deploy a new version applying the steps from the top. Skip 2. as you already have the maintenance enabled.
   <!-- TODO: add how to revert a failed deployment-->
   1. To revert to an earlier version see the How to revert a failed deployment
1. Make the deployment publicly available. Deploy once more with [`Deploy new core version`](https://github.com/graasp/graasp-infrastructure/actions/workflows/deploy-core-version.yml), this time in the `running` state.
