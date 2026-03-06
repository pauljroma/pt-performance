/**
 * tools/policy/validate-mcp.ts
 *
 * Validates MCP server configuration files (.mcp.json).
 * Checks required fields, transport enums, and cross-references
 * between servers, tool allowlists, and resource scoping.
 *
 * Usage:
 *   npx tsx tools/policy/validate-mcp.ts <file.mcp.json> [<file2.mcp.json> ...]
 *   npx tsx tools/policy/validate-mcp.ts --all-profiles
 */

import fs from "node:fs";
import path from "node:path";
import { globSync } from "node:fs";

// ── Types ────────────────────────────────────────────────────────

interface McpServer {
  name?: unknown;
  transport?: unknown;
  command?: unknown;
  args?: unknown;
  env?: unknown;
  enabled?: unknown;
}

interface McpConfig {
  version?: unknown;
  profile?: unknown;
  description?: unknown;
  servers?: unknown;
  tool_allowlists?: unknown;
  resource_scoping?: unknown;
}

interface ValidationError {
  file: string;
  issue: string;
  detail?: string;
}

// ── Constants ────────────────────────────────────────────────────

const VALID_TRANSPORTS = ["stdio", "sse", "streamable-http"];

// ── Helpers ──────────────────────────────────────────────────────

function readJson<T>(filePath: string): T {
  if (!fs.existsSync(filePath)) {
    console.error(`File not found: ${filePath}`);
    process.exit(2);
  }
  return JSON.parse(fs.readFileSync(filePath, "utf8")) as T;
}

// ── Validation ───────────────────────────────────────────────────

function validateMcpConfig(
  filePath: string,
  config: McpConfig,
): ValidationError[] {
  const errors: ValidationError[] = [];
  const file = path.basename(filePath);

  // Required top-level fields
  if (typeof config.version !== "string" || !config.version) {
    errors.push({ file, issue: "missing_version", detail: "'version' is required" });
  }

  if (typeof config.profile !== "string" || !config.profile) {
    errors.push({ file, issue: "missing_profile", detail: "'profile' is required" });
  }

  // Servers array
  if (!Array.isArray(config.servers)) {
    errors.push({ file, issue: "missing_servers", detail: "'servers' must be an array" });
    return errors; // can't validate further without servers
  }

  const serverNames = new Set<string>();

  for (let i = 0; i < config.servers.length; i++) {
    const srv = config.servers[i] as McpServer;
    const prefix = `servers[${i}]`;

    // Name
    if (typeof srv.name !== "string" || !srv.name) {
      errors.push({ file, issue: "server_missing_name", detail: `${prefix}: 'name' is required` });
    } else {
      if (serverNames.has(srv.name)) {
        errors.push({ file, issue: "duplicate_server_name", detail: `${prefix}: duplicate name '${srv.name}'` });
      }
      serverNames.add(srv.name);
    }

    // Transport
    if (typeof srv.transport !== "string" || !VALID_TRANSPORTS.includes(srv.transport)) {
      errors.push({
        file,
        issue: "invalid_transport",
        detail: `${prefix}: 'transport' must be one of: ${VALID_TRANSPORTS.join(", ")}`,
      });
    }

    // Command (required for stdio transport)
    if (srv.transport === "stdio" && (typeof srv.command !== "string" || !srv.command)) {
      errors.push({ file, issue: "missing_command", detail: `${prefix}: 'command' is required for stdio transport` });
    }
  }

  // Tool allowlists reference valid server names
  if (config.tool_allowlists && typeof config.tool_allowlists === "object") {
    for (const serverRef of Object.keys(config.tool_allowlists as Record<string, unknown>)) {
      if (!serverNames.has(serverRef)) {
        errors.push({
          file,
          issue: "allowlist_unknown_server",
          detail: `tool_allowlists references unknown server '${serverRef}'`,
        });
      }
      const tools = (config.tool_allowlists as Record<string, unknown>)[serverRef];
      if (!Array.isArray(tools)) {
        errors.push({
          file,
          issue: "allowlist_not_array",
          detail: `tool_allowlists['${serverRef}'] must be an array`,
        });
      }
    }
  }

  // Resource scoping references valid server names
  if (config.resource_scoping && typeof config.resource_scoping === "object") {
    for (const serverRef of Object.keys(config.resource_scoping as Record<string, unknown>)) {
      if (!serverNames.has(serverRef)) {
        errors.push({
          file,
          issue: "scoping_unknown_server",
          detail: `resource_scoping references unknown server '${serverRef}'`,
        });
      }
    }
  }

  return errors;
}

// ── Main ─────────────────────────────────────────────────────────

function main(): void {
  const args = process.argv.slice(2);

  let files: string[] = [];

  if (args.includes("--all-profiles")) {
    const repoRoot = process.cwd();
    const profileDir = path.join(repoRoot, "templates/golden-path/profiles");
    const templateFile = path.join(repoRoot, "templates/golden-path/mcp.json");

    if (fs.existsSync(profileDir)) {
      const entries = fs.readdirSync(profileDir).filter((f) => f.endsWith(".mcp.json"));
      files = entries.map((f) => path.join(profileDir, f));
    }
    if (fs.existsSync(templateFile)) {
      files.unshift(templateFile);
    }
  } else {
    files = args.filter((a) => !a.startsWith("--"));
  }

  if (files.length === 0) {
    console.error("Usage: npx tsx tools/policy/validate-mcp.ts <file.mcp.json> [...]");
    console.error("       npx tsx tools/policy/validate-mcp.ts --all-profiles");
    process.exit(2);
  }

  let totalErrors = 0;
  const allErrors: ValidationError[] = [];

  for (const file of files) {
    const config = readJson<McpConfig>(file);
    const errors = validateMcpConfig(file, config);
    allErrors.push(...errors);
    totalErrors += errors.length;

    if (errors.length === 0) {
      console.log(`  \u2713 ${path.basename(file)}`);
    } else {
      console.log(`  \u2717 ${path.basename(file)} (${errors.length} errors)`);
    }
  }

  // Write report
  const reportDir = path.join(process.cwd(), "dist/reports/policy");
  fs.mkdirSync(reportDir, { recursive: true });
  fs.writeFileSync(
    path.join(reportDir, "validate-mcp.json"),
    JSON.stringify(
      {
        timestamp: new Date().toISOString(),
        totalFiles: files.length,
        totalErrors,
        errors: allErrors,
      },
      null,
      2,
    ),
  );

  console.log(`\nvalidate-mcp — ${files.length} files, ${totalErrors} errors`);

  if (totalErrors > 0) {
    console.error("\nViolations:");
    for (const e of allErrors) {
      console.error(`  - ${e.file}: ${e.detail ?? e.issue}`);
    }
    console.error(`\nReport: dist/reports/policy/validate-mcp.json`);
    process.exit(1);
  }

  console.log("All MCP configs are valid.");
  console.log(`Report: dist/reports/policy/validate-mcp.json`);
}

main();
