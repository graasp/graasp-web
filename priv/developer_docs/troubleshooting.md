%{
title: "Troubleshooting",
description: "Common issues when setting up the development environment and their workarounds",
order: 20
}

---

Common issues and their workaround

> #### Info {: .info}
>
> If you do not find a solution to your issue here, contact us via GitHub by opening an issue.
> If you find a solution about a problem you faced, please let us know so we can add them to this page, for future users.

## Make sure you have installed dependencies

Run `yarn` at the root of the project (same level as the package.json file). You should see a `node_modules` folder get generated.

## No such file or directory when running `yarn`

When you run `yarn` and you get an error similar to:

```
Internal Error: ENOENT: no such file or directory, stat '/Users/<path-to-directory>/.yarn/releases/yarn-4.1.0.cjs'
```

This usually means you do not have the yarn executable at the path defined in `.yarnrc.yml` under the `yarnPath` key.

To solve this issue:

1. Comment out the `yarnPath` key in `.yarnrc.yml`
2. Run `yarn set version latest` at the root of the project. This assumes you have yarn available globally (installed using corepack as recommended).
3. Run `yarn`, everything should be fine. Ensure that the `.yarn/releases` folder is commited to source control to remove issues like these in the future. See which files should be ignored in [the Yarn Q&A](https://yarnpkg.com/getting-started/qa#which-files-should-be-gitignored)

## CORS error with app

Apps need to be registered with a corresponding publisher. Publisher decides which origins are allowed.

> #### Danger {: .error}
>
> The CORS check is done at startup, so if changes are made on the DB, they will take effect only at the next restart.
