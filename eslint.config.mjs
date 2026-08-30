// ESLint flat config for the IMS frontend.
//
// The browser application has no build step and no runtime dependencies; this
// config and the dev-only package.json exist purely so the code can be linted.
// Nothing here is served to a workstation.

import js from "@eslint/js";
import globals from "globals";

export default [
  {
    ignores: ["backend/**", "legacy/**", "database/**", "node_modules/**"],
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
];
