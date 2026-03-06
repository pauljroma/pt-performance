/**
 * tools/protocol/validate-agent-contract.ts
 *
 * Validates agent-contract.json for correct structure, value ranges,
 * and internal consistency. Follows policy-lint.ts pattern exactly.
 *
 * Usage:
 *   npx tsx tools/protocol/validate-agent-contract.ts
 *   npx tsx tools/protocol/validate-agent-contract.ts --verbose
 */

import fs from "node:fs";
import path from "node:path";

// ── Types ────────────────────────────────────────────────────────

interface AgentTypeSpec {
  allowed_methods?: unknown;
  allowed_tools?: unknown;
  blocked_paths?: unknown;
  spend_cap_usd?: unknown;
  max_ttl_seconds?: unknown;
  trust_tier?: unknown;
  required_gates?: unknown;
  max_retries?: unknown;
  read_only?: unknown;
  description?: unknown;
}

interface AgentContract {
  version?: unknown;
  agentTypes?: unknown;
  rules?: {
    forbiddenMethods?: unknown;
    requireGateForRegulatedPaths?: unknown;
    maxSpendPerJobUsd?: unknown;
    enforceTrustTierForDispatch?: unknown;
    validGates?: string[];
    validMethods?: string[];
  };
}

interface ReportError {
  agentType: string;
  issue: string;
  detail?: string;
}

// ── Constants ────────────────────────────────────────────────────

const VALID_METHODS = new Set(["ssh", "codex", "claude", "local"]);
const VALID_GATES = new Set(["W0", "W1", "W2", "W3"]);
const VALID_TOOLS = new Set(["Edit", "Write", "Read", "Bash", "Glob", "Grep", "Agent", "WebFetch", "WebSearch"]);
const VERBOSE = process.argv.includes("--verbose");

// ── Helpers ──────────────────────────────────────────────────────

function readJson<T>(filePath: string): T {
  if (!fs.existsSync(filePath)) {
    console.error(`Required file not found: ${filePath}`);
    process.exit(2);
  }
  return JSON.parse(fs.readFileSync(filePath, "utf8")) as T;
}

function log(msg: string): void {
  if (VERBOSE) console.log(msg);
}

// ── Validation ───────────────────────────────────────────────────

function validateAgentType(name: string, spec: AgentTypeSpec, contract: AgentContract): ReportError[] {
  const errors: ReportError[] = [];
  const validGates = contract.rules?.validGates ?? [...VALID_GATES];
  const validMethods = contract.rules?.validMethods ?? [...VALID_METHODS];

  log(`  Checking ${name}...`);

  // allowed_methods
  if (!Array.isArray(spec.allowed_methods) || spec.allowed_methods.length === 0) {
    errors.push({ agentType: name, issue: "missing_allowed_methods", detail: "allowed_methods must be a non-empty array" });
  } else {
    for (const m of spec.allowed_methods as unknown[]) {
      if (!validMethods.includes(String(m))) {
        errors.push({ agentType: name, issue: "invalid_method", detail: `'${String(m)}' not in valid methods: ${validMethods.join(", ")}` });
      }
    }
  }

  // spend_cap_usd
  if (typeof spec.spend_cap_usd !== "number" || spec.spend_cap_usd < 0) {
    errors.push({ agentType: name, issue: "invalid_spend_cap", detail: "spend_cap_usd must be a non-negative number" });
  }

  // max_ttl_seconds
  if (typeof spec.max_ttl_seconds !== "number" || spec.max_ttl_seconds < 30 || spec.max_ttl_seconds > 7200) {
    errors.push({ agentType: name, issue: "invalid_ttl", detail: "max_ttl_seconds must be 30-7200" });
  }

  // trust_tier
  if (typeof spec.trust_tier !== "number" || spec.trust_tier < 0 || spec.trust_tier > 3 || !Number.isInteger(spec.trust_tier)) {
    errors.push({ agentType: name, issue: "invalid_trust_tier", detail: "trust_tier must be integer 0-3" });
  }

  // required_gates
  if (!Array.isArray(spec.required_gates)) {
    errors.push({ agentType: name, issue: "missing_required_gates", detail: "required_gates must be an array (can be empty)" });
  } else {
    for (const g of spec.required_gates as unknown[]) {
      if (!validGates.includes(String(g))) {
        errors.push({ agentType: name, issue: "invalid_gate", detail: `'${String(g)}' not in valid gates: ${validGates.join(", ")}` });
      }
    }
  }

  // max_retries
  if (typeof spec.max_retries !== "number" || spec.max_retries < 0 || spec.max_retries > 10 || !Number.isInteger(spec.max_retries)) {
    errors.push({ agentType: name, issue: "invalid_max_retries", detail: "max_retries must be integer 0-10" });
  }

  // read_only consistency: if read_only=true, should only have Read/Glob/Grep in allowed_tools
  if (spec.read_only === true && Array.isArray(spec.allowed_tools)) {
    const writingTools = (spec.allowed_tools as unknown[]).filter((t) => ["Edit", "Write", "Bash"].includes(String(t)));
    if (writingTools.length > 0) {
      errors.push({ agentType: name, issue: "read_only_but_write_tools", detail: `read_only=true but allowed_tools contains writing tools: ${writingTools.join(", ")}` });
    }
  }

  // spend_cap vs global max
  const globalMax = contract.rules?.maxSpendPerJobUsd;
  if (typeof spec.spend_cap_usd === "number" && typeof globalMax === "number") {
    if (spec.spend_cap_usd > globalMax) {
      errors.push({ agentType: name, issue: "spend_cap_exceeds_global", detail: `spend_cap_usd ${spec.spend_cap_usd} exceeds maxSpendPerJobUsd ${globalMax}` });
    }
  }

  return errors;
}

// ── Main ─────────────────────────────────────────────────────────

function main(): void {
  const repoRoot = process.cwd();
  const contractPath = path.join(repoRoot, "tools/protocol/agent-contract.json");
  const contract = readJson<AgentContract>(contractPath);

  const errors: ReportError[] = [];

  // Top-level required fields
  if (typeof contract.version !== "string") {
    console.error("agent-contract.json: missing 'version'");
    process.exit(2);
  }
  if (!contract.agentTypes || typeof contract.agentTypes !== "object") {
    console.error("agent-contract.json: missing 'agentTypes'");
    process.exit(2);
  }
  if (!contract.rules || typeof contract.rules !== "object") {
    console.error("agent-contract.json: missing 'rules'");
    process.exit(2);
  }

  const agentTypes = contract.agentTypes as Record<string, AgentTypeSpec>;
  const typeNames = Object.keys(agentTypes);

  console.log(`\nvalidate-agent-contract — ${typeNames.length} agent types (v${String(contract.version)})\n`);

  for (const [name, spec] of Object.entries(agentTypes)) {
    const typeErrors = validateAgentType(name, spec, contract);
    errors.push(...typeErrors);

    if (typeErrors.length === 0) {
      console.log(`  ✓ ${name}`);
    } else {
      console.log(`  ✗ ${name} (${typeErrors.length} errors)`);
    }
  }

  // Write report
  const reportDir = path.join(repoRoot, "dist/reports/protocol");
  fs.mkdirSync(reportDir, { recursive: true });
  fs.writeFileSync(
    path.join(reportDir, "agent-contract.json"),
    JSON.stringify(
      {
        contractVersion: String(contract.version),
        timestamp: new Date().toISOString(),
        totalTypes: typeNames.length,
        passedTypes: typeNames.length - new Set(errors.map((e) => e.agentType)).size,
        failedTypes: new Set(errors.map((e) => e.agentType)).size,
        errors,
      },
      null,
      2,
    ),
  );

  console.log(`\nvalidate-agent-contract — ${typeNames.length} types, ${errors.length} errors`);

  if (errors.length > 0) {
    console.error("\nViolations:");
    for (const e of errors) console.error(`  - ${e.agentType}: ${e.detail ?? e.issue}`);
    console.error("\nReport: dist/reports/protocol/agent-contract.json");
    process.exit(1);
  }

  console.log("All agent types conform to contract rules.");
  console.log("Report: dist/reports/protocol/agent-contract.json");
}

main();
