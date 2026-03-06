/** Shared repo-root resolution for CLI tools. */
import path from "node:path";

export const REPO_ROOT = path.resolve(
  path.dirname(new URL(import.meta.url).pathname),
  "../.."
);
