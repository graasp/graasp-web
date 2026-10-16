%{
title: "Migrate to Eslint v9",
description: "Migrate a React Typescript project to eslint v9 flat configs",
order: 20
}

---

In this document we describe **how to migrate to eslint v9** using the new flat-configs in your React Typescript project.

## Migration tools

Use the auto-migration tool:

```sh
npx @eslint/migrate-config .eslintrc
```

It will migrate your `.eslintrc` config file to the new eslint v9 flatConfig format.

Make sure it works as expected, you may have to remove some ignore comments and so on.

Also remove the old config and check that the new config is picked up by your IDE and cli tool.

## Using eslint v9 with `vite-plugin-checker` {: #eslint-with-vite-plugin-checker}

You will need to add the `useFlatConfig: true` to the plugin config:

```ts
import { UserConfigExport, defineConfig } from 'vite';
import checker from 'vite-plugin-checker';

// https://vitejs.dev/config/
export default (): UserConfigExport => {
  return defineConfig({
    plugins: [
      checker({
        eslint: {
          // 👇 Need to add this line
          useFlatConfig: true, 
          // rest of your config ...
        },
        // config of other tools supported by checker
      })
      // other plugins ...
    ],
  });
};

```
