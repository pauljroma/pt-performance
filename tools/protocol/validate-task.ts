/**
 * tools/protocol/validate-task.ts
 *
 * Validates TaskEnvelope JSON files against task-schema.json.
 * Cross-checks constraints against agent-contract.json (budget caps, allowed methods).
 *
 * Usage:
 *   npx tsx tools/protocol/validate-task.ts <file.json> [<file2.json> ...]
 *   npx tsx tools/protocol/validate-task.ts --all-examples
 */

import fs from "node:fs";
import path from "node:path";

// ── Types ────────────────────────────────────────────────────────

interface TaskEnvelope {
  task_id?: unknown;
  parent_task_id?: unknown;
  intent?: unknown;
  scope?: {
    machine?: unknown;
    repo?: unknown;
    zone?: unknown;
    paths?: unknown;
  };
  constraints?: {
    method?: unknown;
    timeout_s?: unknown;
    budget_usd?: unknown;
    trust_tier?: unknown;
    agent_type?: unknown;
  };
  deadline?: unknown;
  agent_affinity?: unknown;
  priority?: unknown;
  metadata?: unknown;
}

interface AgentTypeSpec {
  allowed_methods?: string[];
  spend_cap_usd?: number;
  trust_tier?: number;
  max_ttl_seconds?: number;
}

interface AgentContract {
  version: string;
  agentTypes: Record<string, AgentTypeSpec>;
  rules: {
    maxSpendPerJobUsd?: number;
    enforceTrustTierForDispatch?: boolean;
  };
}

interface ValidationError {
  file: string;
  issue: string;
  detail?: string;
}

// ── Constants ────────────────────────────────────────────────────

const VALID_METHODS = ["ssh", "codex", "claude", "local"];
const VALID_AGENT_TYPES = ["engineer", "reviewer", "swat", "deployer", "auditor"];
const VALID_GATES = ["W0", "W1", "W2", "W3"];
const TASK_ID_PATTERN = /^task-\d{8}-\d{4}$/;
const ZONE_PATTERN = /^z\d{2}(_[a-z_]+)?$/;

// ── Helpers ──────────────────────────────────────────────────────

function readJson<T>(filePath: string): T {
  if (!fs.existsSync(filePath)) {
    console.error(`File not found: ${filePath}`);
    process.exit(2);
  }
  return JSON.parse(fs.readFileSync(filePath, "utf8")) as T;
}

// ── Validation ───────────────────────────────────────────────────

function validateTask(
  filePath: string,
  task: TaskEnvelope,
  contract: AgentContract,
): ValidationError[] {
  const errors: ValidationError[] = [];
  const file = path.basename(filePath);

  // task_id
  if (typeof task.task_id !== "string" || !TASK_ID_PATTERN.test(task.task_id)) {
    errors.push({ file, issue: "invalid_task_id", detail: `task_id must match pattern task-YYYYMMDD-NNNN, got: ${String(task.task_id)}` });
  }

  // intent
  if (typeof task.intent !== "string" || task.intent.length < 10 || task.intent.length > 500) {
    errors.push({ file, issue: "invalid_intent", detail: "intent must be 10-500 characters" });
  }

  // scope
  if (!task.scope || typeof task.scope !== "object") {
    errors.push({ file, issue: "missing_scope", detail: "scope object is required" });
  } else {
    if (typeof task.scope.machine !== "string" || !task.scope.machine) {
      errors.push({ file, issue: "missing_scope_machine", detail: "scope.machine is required" });
    }
    if (task.scope.zone !== undefined && (typeof task.scope.zone !== "string" || !ZONE_PATTERN.test(task.scope.zone))) {
      errors.push({ file, issue: "invalid_zone", detail: `scope.zone must match z##_name pattern, got: ${String(task.scope.zone)}` });
    }
  }

  // constraints
  if (!task.constraints || typeof task.constraints !== "object") {
    errors.push({ file, issue: "missing_constraints", detail: "constraints object is required" });
    return errors;
  }

  const c = task.constraints;

  if (!VALID_METHODS.includes(String(c.method))) {
    errors.push({ file, issue: "invalid_method", detail: `constraints.method must be one of: ${VALID_METHODS.join(", ")}` });
  }

  if (typeof c.timeout_s !== "number" || c.timeout_s < 30 || c.timeout_s > 3600) {
    errors.push({ file, issue: "invalid_timeout", detail: "constraints.timeout_s must be 30-3600" });
  }

  if (c.trust_tier !== undefined && (typeof c.trust_tier !== "number" || c.trust_tier < 0 || c.trust_tier > 3)) {
    errors.push({ file, issue: "invalid_trust_tier", detail: "constraints.trust_tier must be 0-3" });
  }

  if (typeof c.priority !== "undefined" && task.priority !== undefined) {
    const p = task.priority as number;
    if (typeof p !== "number" || p < 0 || p > 5) {
      errors.push({ file, issue: "invalid_priority", detail: "priority must be 0-5" });
    }
  }

  // Cross-check against agent-contract.json
  const agentType = String(c.agent_type ?? "");
  if (agentType && !VALID_AGENT_TYPES.includes(agentType)) {
    errors.push({ file, issue: "invalid_agent_type", detail: `constraints.agent_type must be one of: ${VALID_AGENT_TYPES.join(", ")}` });
  } else if (agentType && contract.agentTypes[agentType]) {
    const typeSpec = contract.agentTypes[agentType];

    // Budget cap check
    if (typeof c.budget_usd === "number" && typeSpec.spend_cap_usd !== undefined) {
      if (c.budget_usd > typeSpec.spend_cap_usd) {
        errors.push({
          file,
          issue: "budget_exceeds_type_cap",
          detail: `budget_usd ${c.budget_usd} exceeds ${agentType} cap ${typeSpec.spend_cap_usd}`,
        });
      }
    }

    // Global max spend check
    if (typeof c.budget_usd === "number" && contract.rules.maxSpendPerJobUsd !== undefined) {
      if (c.budget_usd > contract.rules.maxSpendPerJobUsd) {
        errors.push({
          file,
          issue: "budget_exceeds_global_max",
          detail: `budget_usd ${c.budget_usd} exceeds global max ${contract.rules.maxSpendPerJobUsd}`,
        });
      }
    }

    // Method allowed check
    if (typeSpec.allowed_methods && typeof c.method === "string") {
      if (!typeSpec.allowed_methods.includes(c.method)) {
        errors.push({
          file,
          issue: "method_not_allowed_for_type",
          detail: `method '${c.method}' not allowed for ${agentType}. Allowed: ${typeSpec.allowed_methods.join(", ")}`,
        });
      }
    }

    // Timeout check
    if (typeof c.timeout_s === "number" && typeSpec.max_ttl_seconds !== undefined) {
      if (c.timeout_s > typeSpec.max_ttl_seconds) {
        errors.push({
          file,
          issue: "timeout_exceeds_type_max",
          detail: `timeout_s ${c.timeout_s} exceeds ${agentType} max_ttl_seconds ${typeSpec.max_ttl_seconds}`,
        });
      }
    }
  }

  return errors;
}

// ── Main ─────────────────────────────────────────────────────────

function main(): void {
  const args = process.argv.slice(2);
  const repoRoot = process.cwd();
  const contractPath = path.join(repoRoot, "tools/protocol/agent-contract.json");

  let files: string[] = [];

  if (args.includes("--all-examples")) {
    const examplesDir = path.join(repoRoot, "tools/protocol/examples");
    if (fs.existsSync(examplesDir)) {
      files = fs.readdirSync(examplesDir)
        .filter((f) => f.endsWith(".json"))
        .map((f) => path.join(examplesDir, f));
    }
  } else {
    files = args.filter((a) => !a.startsWith("--"));
  }

  if (files.length === 0) {
    console.error("Usage: npx tsx tools/protocol/validate-task.ts <file.json> [...]");
    console.error("       npx tsx tools/protocol/validate-task.ts --all-examples");
    process.exit(2);
  }

  // Load contract (may not exist yet — degrade gracefully)
  let contract: AgentContract = { version: "0.0.0", agentTypes: {}, rules: {} };
  if (fs.existsSync(contractPath)) {
    contract = readJson<AgentContract>(contractPath);
  } else {
    console.warn("  ⚠ agent-contract.json not found — skipping cross-contract validation");
  }

  let totalErrors = 0;
  const allErrors: ValidationError[] = [];

  for (const file of files) {
    const task = readJson<TaskEnvelope>(file);
    const errors = validateTask(file, task, contract);
    allErrors.push(...errors);
    totalErrors += errors.length;

    if (errors.length === 0) {
      console.log(`  ✓ ${path.basename(file)}`);
    } else {
      console.log(`  ✗ ${path.basename(file)} (${errors.length} errors)`);
    }
  }

  // Write report
  const reportDir = path.join(repoRoot, "dist/reports/protocol");
  fs.mkdirSync(reportDir, { recursive: true });
  fs.writeFileSync(
    path.join(reportDir, "validate-task.json"),
    JSON.stringify({ timestamp: new Date().toISOString(), totalFiles: files.length, totalErrors, errors: allErrors }, null, 2),
  );

  console.log(`\nvalidate-task — ${files.length} files, ${totalErrors} errors`);
  if (totalErrors > 0) {
    for (const e of allErrors) console.error(`  - ${e.file}: ${e.detail ?? e.issue}`);
    process.exit(1);
  }
  console.log("All task envelopes are valid.");
}

main();
