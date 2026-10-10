%{
title: "Release Please",
description: "How we use release-please and how to fix a failed release",
order: 2
}

---

In this document we compile the behavior of the [`release-please`](https://github.com/googleapis/release-please) component.
This component is provided by Google. We use [the Github Action provided by Google](https://github.com/googleapis/release-please-action). The repo contains some general documentation that is of interest to understand the general behavior of the tool.

In this document we will focus on our usage of the tool and how to "fix" it when it fails (which has happened in the past).
<!-- FIXME: Should we move the "how to fix it" part to a "how to guide" ? -->

## How we use the tool and what it is supposed to do

We rely on `release-please` to:

- detect releasable changes
- create the release proposals
- generate releases in github
- tag the release
- notify our deployment pipeline that a new release is available

Let's break these down and explain each one.

### Detect releasable changes {: #releasable-changes}

`release-please` relies on [conventional commits](https://www.conventionalcommits.org/en/v1.0.0) to detect the type of change that is made on your main branch.

### Create a release proposal

When a releasable change is detected on your main branch, `release-please` creates a PR with that change.
Commits tagged with `fix`, `feat`, `docs` are considered releasable changes.
Commits that are `chore`, `build`, `ci` etc... are **not** considered releasable changes.

> #### Warning {: .warning}
>
> Make sure you merge commits with explicitly releasable names following the conventional commit nomenclature since `release-please` will not create a release if you tag them with `awesome feature !` for example.
> Make sure your PR title follows the conventional commits !

### Generate releases in GitHub

Once you are satisfied with the PR proposal, you can merge it. This will trigger the `release-please` release process. It will create a github release with the content of the PR body as the release text.

Additionally we also create a tag attached to the release commit.

## Release please did not create the release correctly

Given the information state in the previous section, failure to completely execute the release-please workflow may result in a wrong state and a skipped release.

To fix this issue, we outline the steps that need to be taken to manually create the tag, release, and notify the deployment pipeline of the new version.

### Fixing a failed release {: #fix-release-please}

First check if:

1. a release commit was done by release-please
1. a tag with the expected version as name was created
1. a release was published in github
1. the new version was notified to the deployment pipeline

Depending on how far release-please was able to go, pick-up the instructions at the correct point.

If you merged the release-please PR and do not see a `chore(main): release x.y.z (#XXX)` commit on main, then you need to create one yourself. In this case it is likely that the release-please workflow has failed before it was able to commit anything. Ensure this is not an issue with access tokens.

If you do not see a tag named `vX.Y.Z` where `X.Y.Z` is the version you are trying to release, ensure your local copy of the repo is up-to-date. For there, create a tag with the command `git tag vX.Y.Z` replace `X.Y.Z` with your specific version: `git tag v1.45.7`.
Push the tag by using the `git push --tags` you should see the newly created tag be pushed to your repository.

If you do not see a github release, you should create it. Navigate to the "Releases" page of your repo (you can find it on the right side of the repo home page). Then select "Draft a new release" button to access the release creation page (it can also be accessed with the url: `https://github.com/OWNER/REPO/releases/new`).
There you should select the tag that matches the version you want to release, add the necessary title (usually the version name `vX.Y.Z`) and the body (you can copy what release-please did in the PR). Check the `Set as the latest release` option and click `Publish release`.

If you did everything right, you should be able to trigger a staging deployment and the pipeline should see that your component's new version is available for deployment.
