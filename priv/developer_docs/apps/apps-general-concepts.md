%{
title: "General concepts",
order: 2
}

---

Graasp can embed web applications as a resource. They should be added as an item of type `app` to access the Graasp API and get authenticated with a token.

When an app is added as a resource, it is linked to an item. Therefore, two added apps will correspond to two different items, which leads them to have different item ids, and different app data.

## Features

### App Context {: #app-context}

The app context contains additional information which might be interesting for your app such as `members` or `item`.

The `members` key contains the list of users that have a permission on the item, this does not include users viewing the app in public mode. You can use this list to display the name of a user that has created some data in your app for example.

The `item` key contains the properties of the item (the app instance) such as `name`, `description`, `path` etc.

### App Actions {: #app-actions}

App actions are analytic traces the app might save.

You can only GET and POST app actions, it is not possible to delete app actions after their creation.

### App Data {: #app-data}

App data are all data the app might save. App Data are created by a member and are available to in a given scope.

- **Visibility**: Availability of the app data, either `member` or `item` (default: `member`).
  - `member`: the app data can be managed by the creator and members with admin permission. Members with write permission can view them but cannot modify them.
  - `item`: the app data can be managed by the creator and members with admin permission. All other members can view them but cannot modify them.

> #### More on permissions {: .info}
>
> Have look at the [permissions section](./apps-permissions) for more details on the visibility of app data and the associated permissions.

### App Settings {: #app-settings}

App settings store the app configuration. Only members with the admin permission can create, update and delete them. The other members can only fetch the app settings.

If the related item is copied, its app settings are copied alongside, opposed to app data.

### File Upload

Apps can upload files, as (app) data or (app) setting.
