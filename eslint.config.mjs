// ESLint flat config for the IMS frontend.
//
// The browser application has no build step and no runtime dependencies; this
// config and the dev-only package.json exist purely so the code can be linted.
// Nothing here is served to a workstation.

import js from "@eslint/js";
import globals from "globals";

export default [
  {
    ignores: [
      "backend/**",
      "legacy/**",
      "database/**",
      "node_modules/**",
      "desktop/node_modules/**",
      "desktop/src-tauri/**",
    ],
  },
  js.configs.recommended,
  {
    files: ["frontend/**/*.js"],
    languageOptions: {
      ecmaVersion: 2022,
      sourceType: "module",
      globals: {
        ...globals.browser,
      },
    },
    rules: {
      // A leading underscore marks a binding that is intentionally unused.
      "no-unused-vars": ["error", { argsIgnorePattern: "^_", varsIgnorePattern: "^_" }],
      eqeqeq: ["error", "smart"],
      "prefer-const": "error",
      "no-var": "error",
      "object-shorthand": "warn",
      "no-implicit-coercion": "warn",
      "no-console": ["warn", { allow: ["warn", "error"] }],
    },
  },
  {
    // The desktop launcher (desktop/ui/). Same rules, but a classic script
    // rather than a module: it runs with `withGlobalTauri`, so the whole Tauri
    // API arrives as a global and there is nothing to import.
    files: ["desktop/ui/**/*.js"],
    languageOptions: {
      ecmaVersion: 2022,
      sourceType: "script",
      globals: {
        ...globals.browser,
      },
    },
    rules: {
      "no-unused-vars": ["error", { argsIgnorePattern: "^_", varsIgnorePattern: "^_" }],
      eqeqeq: ["error", "smart"],
      "prefer-const": "error",
      "no-var": "error",
      "object-shorthand": "warn",
      "no-implicit-coercion": "warn",
      "no-console": ["warn", { allow: ["warn", "error"] }],
    },
  },
];
