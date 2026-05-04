---
title: May 4th, Fixes and improvements
description: Bug fixes and performance improvements
authors:
  - Graasp
---

This is our monthly update that ships bug fixes and quality of life improvements. We are making constant changes to improve the experience of using Graasp. Read below for the complete list of changes included in this release.

<!-- truncate -->

## Improvements to the authentication error

In this release we worked on improving authentication error messages. This should allow users to better understand why they can not log in. In previous versions when an expired login link was used, a blank page was displayed. We now handle this more gracefuly and invite the user to log in again.

## Supporting Japanese

We are happy to share that the ground work has been done so that Graasp can be used in Japanese. We are still missing complete translations in the interface but will be adding them shortly. If you would like to contribute to the translations in Japanese or any other currently supported language please reach out to us by email: [translations@graasp.org](mailto:translations@graasp.org)

## Self-hosting improvements

If you are self-hosting Graasp, this release of the client fixes issues building and running the project on your own machines.

## Automatic trash compacting process

As announced in our banner in January we are starting to permanently delete elements that have been in the trash for more than 3 months. This process will run in the background. No action is required on your part. The documents affected are not displayed in the trash view anymore. You can still restore recently deleted documents from your trash.

## Misc. improvements

When reloading the page in analytics it correctly replies with the analytics page.

Fix an ordering issues when creating a folder with a thumbnail, all new elements should be added after the last element.

<!-- Generic message -->

We warmly welcome and encourage feedback from our users to continuously improve our platform. You can contact us by email [admin@graasp.org](mailto:admin@graasp.org) or by submitting an issue in this [Github repository](https://github.com/graasp/graasp-feedback).
