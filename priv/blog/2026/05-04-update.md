---
title: May 4th, Fixes and improvements
description: Bug fixes and performance improvements
authors:
  - Graasp
---

This is our monthly update that includes bug fixes and quality of life improvements. We are making constant changes to improve the experience of using Graasp. Read below for the complete list of changes included in this release.

<!-- truncate -->

## Improvements to authentication error messages

In this release, we worked on improving authentication error messages. This should allow users to better understand why they cannot log in. In previous versions, using an expired login link resulted in a blank page. We now handle this more gracefully and invite the user to log in again.

## Supporting Japanese

We are happy to share that the groundwork has been done so that Graasp can be used in Japanese. We are still missing complete translations in the user interface but will be adding them shortly. If you would like to contribute to the translations in Japanese or any other currently supported language, please reach out to us by email: [translations@graasp.org](mailto:translations@graasp.org)

## Self-hosting improvements

If you are self-hosting Graasp, this release of the client fixes issues with building and running the project on your own machines.

## Automatic trash cleanup

As announced in our banner in January, we are starting to permanently delete elements that have been in the trash for more than 3 months. This process will run in the background. No action is required on your part. The affected documents are no longer displayed in the trash view. You can still restore recently deleted documents from your Trash.

## Misc. improvements

When reloading the page in Analytics, it now correctly reloads the analytics view.

Fix an ordering issue when creating a folder with a thumbnail, all new elements should be added after the last element.

<!-- Generic message -->

We warmly welcome and encourage feedback from our users to continuously improve our platform. You can contact us by email [admin@graasp.org](mailto:admin@graasp.org) or by submitting an issue in this [Github repository](https://github.com/graasp/graasp-feedback).
