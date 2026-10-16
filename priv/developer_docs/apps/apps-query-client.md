%{
title: "Query client",
description: "",
order: 7
}

---

As you start to build your app from [the template](./apps-template), you will see that it comes with a pre-configured query client. This configuration is located in `src/config/queryClient.ts` and contains everything you need to configure the apps query client.

More informations on how to use the query client can be found in [its repo](https://github.com/graasp/graasp-apps-query-client).

> #### Still under construction {: .warning}
>
> This documentation is still under construction.

### queryClient.ts

```ts
import { configureQueryClient } from "@graasp/apps-query-client";

import notifier from "@/utils/notifier";

import { API_HOST, GRAASP_APP_KEY, MOCK_API, WS_HOST } from "./env";

const {
  queryClient,
  QueryClientProvider,
  hooks,
  API_ROUTES,
  mutations,
  ReactQueryDevtools,
  QUERY_KEYS,
} = configureQueryClient({
  API_HOST,
  notifier,
  refetchOnWindowFocus: !import.meta.env.DEV,
  keepPreviousData: true,
  // avoid refetching when same data are closely fetched
  staleTime: 1000, // ms
  GRAASP_APP_KEY,
  isStandalone: MOCK_API,
  WS_HOST,
  enableWebsocket: true,
});

export {
  ReactQueryDevtools,
  queryClient,
  QueryClientProvider,
  hooks,
  mutations,
  API_ROUTES,
  QUERY_KEYS,
};
```

### Configuring the apps query client

The configure query client, let's breakdown the initial configuration passed to the function `configureQueryClient`:

```ts
configureQueryClient({
  API_HOST,
  notifier,
  refetchOnWindowFocus: !import.meta.env.DEV,
  keepPreviousData: true,
  // avoid refetching when same data are closely fetched
  staleTime: 1000, // ms
  GRAASP_APP_KEY,
  isStandalone: MOCK_API,
  WS_HOST,
  enableWebsocket: true,
});
```

- `API_HOST`: The default API host. This should be configured to point toward the Graasp API or your local development server.
- `notifier`: A function of type [`Notifier`](https://github.com/graasp/graasp-apps-query-client/blob/main/src/types.ts#L16) to process messages from the query client.
- `refetchOnWindowFocus`: The name is explicit.
- `keepPreviousData`: Keep current data when refetching new data.
- `staleTime`: Time during which the data cannot be refetched after a fetch.
- `GRAASP_APP_KEY`: The key of your application. This key must match the one in the database. Think about requesting one when you will deploy your app in production and use it on [graasp.org](https://graasp.org).
- `isStandalone`: If true, the query client will consider that the app **is not** embedded in another frontend such as the _Graasp Player_ or _Graasp Builder_.
- `WS_HOST`: Provide the host for the websocket API.
- `enableWebsocket`: Enable the protocol for realtime notifications by the server through websockets.

### Using the apps query client

After configuration, the query client returns multiple objects that you can use throughout your app.

#### `queryClient`

This object represents the query client. You mostly need to passe it to the `QueryClientProvider`.

#### `QueryClientProvider`

This is the context in which you can put all the logic that requires the query client. Usually, you will encapsulate most of your app in this context to allow your components to use the configured query client.

In the template app, this context is setup in the **Root** component.

```tsx
import {
  GraaspContextDevTool,
  WithLocalContext,
  WithTokenContext,
  useObjectState,
} from "@graasp/apps-query-client";

// Logic, theme and other stuff...

const Root: FC = () => {
  // Logic of the Root...
  return (
    <QueryClientProvider client={queryClient}>
      <WithLocalContext
        defaultValue={window.Cypress ? window.appContext : mockContext}
        LoadingComponent={<Loader />}
        useGetLocalContext={hooks.useGetLocalContext}
        useAutoResize={hooks.useAutoResize}
        onError={() => {
          // eslint-disable-next-line no-console
          console.error("An error occurred while fetching the context.");
        }}
      >
        <WithTokenContext
          LoadingComponent={<Loader />}
          useAuthToken={hooks.useAuthToken}
          onError={() => {
            // eslint-disable-next-line no-console
            console.error("An error occurred while requesting the token.");
          }}
        >
          {/* This is where your app can use the query client. */}
          <App />
          {import.meta.env.DEV && (
            <GraaspContextDevTool
              members={mockMembers}
              context={mockContext}
              setContext={setMockContext}
            />
          )}
        </WithTokenContext>
      </WithLocalContext>
      {import.meta.env.DEV && <ReactQueryDevtools position="bottom-left" />}
    </QueryClientProvider>
  );
};
```

#### `hooks`

The hooks are special functions that you can use to fetch data. To understand the general concept of hooks in React, see [the hooks documentation](https://react.dev/reference/react/hooks).

Hooks are available for the three data domains, [app data](apps-general-concepts#app-data), [app settings](apps-general-concepts#app-settings), and [app actions](apps-general-concepts#app-actions). The `hooks` object contains all the hooks.

<!-- TODO: complete links -->

All the hooks described below are using the [`useQuery`](https://tanstack.com/query/v4/docs/framework/react/reference/useQuery) hook provided by the [TanStack Query package v4](https://tanstack.com/query/v4/docs/framework/react/overview).

##### `useAppData`

With this hook, you can query the app data. The hook returns an object containing the `data` property. This property contains the array of [`AppData`](https://github.com/graasp/graasp-sdk/tree/main/src/app/app.ts#L48) type.

##### `useAppDataFile`

_To be completed. See [`useAppDataFile`](https://github.com/graasp/graasp-apps-query-client/tree/main/src/hooks/appData.ts#L57)._

##### `useAppSettings`

The `data` property is an array of [`AppSetting`](https://github.com/graasp/graasp-sdk/tree/main/src/app/app.ts#L60).

##### `useAppSettingFile`

_To be completed. See [`useAppSettingFile`](https://github.com/graasp/graasp-apps-query-client/src/main/src/hooks/appSetting.ts#L53)._

##### `useAppActions`

The `data` property is an array of [`AppAction`](https://github.com/graasp/graasp-sdk/tree/main/src/app/app.ts#L34).

#### `mutations`

_To be completed. See [mutations](https://github.com/graasp/graasp-apps-query-client/tree/main/src/mutations)._

<!-- #### `API_ROUTES` -->

#### `ReactQueryDevtools`

This component can be used to display panel in your app to help you debug the query client.

<!-- #### `QUERY_KEYS` -->
