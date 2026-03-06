/**
 * tools/policy/spend-gate.ts
 *
 * Spend enforcement gate for the develop-cc agent fleet.
 * Reads caps from tools/protocol/agent-contract.json.
 * Persists ledger in tools/protocol/.state/spend-ledger.json.
 *
 * Subcommands:
 *   check  <agent-type> <estimated-usd>   — exits 0 if under cap, 1 if over
 *   record <agent-id> <agent-type> <usd> [--trace-id X] — append to ledger
 *   status [--agent-type X]               — table: spent/cap/remaining
 *   reset  [--force]                       — weekly reset (guards accidental reset)
 *
 * Usage:
 *   npx tsx tools/policy/spend-gate.ts check engineer 4.50
 *   npx tsx tools/policy/spend-gate.ts record x2m-alpha-engineer-01 engineer 1.23 --trace-id trc-abc123
 *   npx tsx tools/policy/spend-gate.ts status
 *   npx tsx tools/policy/spend-gate.ts status --agent-type engineer
 *   npx tsx tools/policy/spend-gate.ts reset --force
 */

import fs from "node:fs";
import path from "node:path";
import { RESET, BOLD, RED, GREEN, YELLOW, CYAN } from "../lib/colors.js";
import { REPO_ROOT } from "../lib/paths.js";

// ── Types ─────────────────────────────────────────────────────────

interface AgentTypeSpec {
  spend_cap_usd?: number;
}

interface AgentContract {
  agentTypes?: Record<string, AgentTypeSpec>;
  rules?: {
    maxSpendPerJobUsd?: number;
  };
}

interface AgentEntry {
  spent_usd: number;
  cap_usd: number;
  job_count: number;
  last_trace_id?: string;
  last_updated?: string;
}

interface TypeEntry {
  spent_usd: number;
  cap_usd: number;
  job_count: number;
}

interface SpendLedger {
  week_start: string;
  by_type: Record<string, TypeEntry>;
  by_agent: Record<string, AgentEntry>;
  last_updated: string;
}

// ── Constants ─────────────────────────────────────────────────────

const CONTRACT_PATH = path.join(REPO_ROOT, "tools/protocol/agent-contract.json");
const STATE_DIR = path.join(REPO_ROOT, "tools/protocol/.state");
const LEDGER_PATH = path.join(STATE_DIR, "spend-ledger.json");

// ── Helpers ───────────────────────────────────────────────────────

function readContract(): AgentContract {
  if (!fs.existsSync(CONTRACT_PATH)) {
    console.error(`agent-contract.json not found: ${CONTRACT_PATH}`);
    process.exit(2);
  }
  return JSON.parse(fs.readFileSync(CONTRACT_PATH, "utf8")) as AgentContract;
}

function readLedger(): SpendLedger {
  if (!fs.existsSync(LEDGER_PATH)) {
    return {
      week_start: getWeekStart(),
      by_type: {},
      by_agent: {},
      last_updated: new Date().toISOString(),
    };
  }
  return JSON.parse(fs.readFileSync(LEDGER_PATH, "utf8")) as SpendLedger;
}

function writeLedger(ledger: SpendLedger): void {
  fs.mkdirSync(STATE_DIR, { recursive: true });
  const tmp = LEDGER_PATH + ".tmp";
  ledger.last_updated = new Date().toISOString();
  fs.writeFileSync(tmp, JSON.stringify(ledger, null, 2));
  fs.renameSync(tmp, LEDGER_PATH);
}

function getWeekStart(): string {
  const now = new Date();
  const day = now.getUTCDay(); // 0=Sun
  const diff = now.getUTCDate() - day + (day === 0 ? -6 : 1); // Monday
  const monday = new Date(now);
  monday.setUTCDate(diff);
  monday.setUTCHours(0, 0, 0, 0);
  return monday.toISOString();
}

function isCurrentWeek(weekStart: string): boolean {
  const ledgerMonday = new Date(weekStart).getTime();
  const currentMonday = new Date(getWeekStart()).getTime();
  return ledgerMonday === currentMonday;
}

function getTypeCap(agentType: string, contract: AgentContract): number {
  const spec = contract.agentTypes?.[agentType];
  if (!spec) return 100; // default
  return spec.spend_cap_usd ?? 100;
}

function formatUsd(val: number): string {
  return `$${val.toFixed(2)}`;
}

function pctColor(spent: number, cap: number): string {
  if (cap <= 0) return CYAN;
  const pct = spent / cap;
  if (pct > 0.95) return RED;
  if (pct > 0.80) return YELLOW;
  return GREEN;
}

// ── Subcommands ───────────────────────────────────────────────────

function cmdCheck(agentType: string, estimatedUsd: number): void {
  const contract = readContract();
  const cap = getTypeCap(agentType, contract);
  const ledger = readLedger();

  // Reset stale week
  if (!isCurrentWeek(ledger.week_start)) {
    ledger.by_type = {};
    ledger.by_agent = {};
    ledger.week_start = getWeekStart();
    writeLedger(ledger);
  }

  const typeEntry = ledger.by_type[agentType];
  const spentSoFar = typeEntry?.spent_usd ?? 0;
  const remaining = cap - spentSoFar;

  const globalMax = contract.rules?.maxSpendPerJobUsd ?? 25;
  const perJobExceeds = estimatedUsd > globalMax;
  const weeklyExceeds = spentSoFar + estimatedUsd > cap;

  if (perJobExceeds) {
    console.error(`BLOCKED — estimated ${formatUsd(estimatedUsd)} exceeds per-job max ${formatUsd(globalMax)}`);
    process.exit(1);
  }

  if (weeklyExceeds) {
    const downgrade = agentType === "swat" ? "engineer" : agentType === "engineer" ? "local" : null;
    console.error(`BLOCKED — ${agentType} weekly cap exhausted. Spent ${formatUsd(spentSoFar)} / ${formatUsd(cap)}`);
    if (downgrade) {
      console.error(`SUGGEST  — downgrade to '${downgrade}' type or reduce estimated cost`);
    }
    process.exit(1);
  }

  const color = pctColor(spentSoFar + estimatedUsd, cap);
  console.log(
    `ALLOWED  — ${agentType} spent ${color}${formatUsd(spentSoFar)}${RESET} + ` +
    `est ${formatUsd(estimatedUsd)} = ${formatUsd(spentSoFar + estimatedUsd)} / ${formatUsd(cap)} ` +
    `(${formatUsd(remaining - estimatedUsd)} remaining)`
  );
}

function cmdRecord(agentId: string, agentType: string, actualUsd: number, traceId?: string): void {
  const contract = readContract();
  const cap = getTypeCap(agentType, contract);

  const ledger = readLedger();

  // Auto-reset stale week
  if (!isCurrentWeek(ledger.week_start)) {
    ledger.by_type = {};
    ledger.by_agent = {};
    ledger.week_start = getWeekStart();
    writeLedger(ledger);
  }

  // Update by_type
  if (!ledger.by_type[agentType]) {
    ledger.by_type[agentType] = { spent_usd: 0, cap_usd: cap, job_count: 0 };
  }
  ledger.by_type[agentType].spent_usd += actualUsd;
  ledger.by_type[agentType].cap_usd = cap;
  ledger.by_type[agentType].job_count += 1;

  // Update by_agent
  if (!ledger.by_agent[agentId]) {
    ledger.by_agent[agentId] = { spent_usd: 0, cap_usd: cap, job_count: 0 };
  }
  ledger.by_agent[agentId].spent_usd += actualUsd;
  ledger.by_agent[agentId].job_count += 1;
  ledger.by_agent[agentId].last_updated = new Date().toISOString();
  if (traceId) ledger.by_agent[agentId].last_trace_id = traceId;

  writeLedger(ledger);
  console.log(
    `RECORDED — ${agentId} (${agentType}) +${formatUsd(actualUsd)} ` +
    `[week total: ${formatUsd(ledger.by_type[agentType].spent_usd)}]` +
    (traceId ? ` trace=${traceId}` : "")
  );
}

function cmdStatus(filterType?: string): void {
  const contract = readContract();
  const ledger = readLedger();
  const stale = !isCurrentWeek(ledger.week_start);

  if (stale) {
    console.log(`${YELLOW}Note: ledger is from week of ${ledger.week_start} (stale — no spending this week)${RESET}\n`);
  }

  const agentTypes = Object.keys(contract.agentTypes ?? {});

  console.log(`${BOLD}Week of: ${ledger.week_start}${RESET}\n`);
  console.log(`${BOLD}By Agent Type:${RESET}`);
  console.log(
    `${BOLD}${"TYPE".padEnd(16)} ${"SPENT".padStart(10)} ${"CAP".padStart(10)} ${"REMAINING".padStart(12)} ${"JOBS".padStart(6)}${RESET}`
  );

  for (const agentType of agentTypes) {
    if (filterType && agentType !== filterType) continue;
    const cap = getTypeCap(agentType, contract);
    const entry = stale ? null : ledger.by_type[agentType];
    const spent = entry?.spent_usd ?? 0;
    const jobs = entry?.job_count ?? 0;
    const remaining = Math.max(0, cap - spent);
    const color = pctColor(spent, cap);

    console.log(
      `${agentType.padEnd(16)} ` +
      `${color}${formatUsd(spent).padStart(10)}${RESET} ` +
      `${formatUsd(cap).padStart(10)} ` +
      `${formatUsd(remaining).padStart(12)} ` +
      `${String(jobs).padStart(6)}`
    );
  }

  if (!filterType) {
    const agents = Object.entries(ledger.by_agent);
    if (agents.length > 0 && !stale) {
      console.log(`\n${BOLD}By Agent Instance:${RESET}`);
      console.log(
        `${BOLD}${"AGENT".padEnd(32)} ${"SPENT".padStart(10)} ${"JOBS".padStart(6)} ${"LAST TRACE".padEnd(22)}${RESET}`
      );
      for (const [agentId, entry] of agents) {
        console.log(
          `${agentId.padEnd(32)} ` +
          `${formatUsd(entry.spent_usd).padStart(10)} ` +
          `${String(entry.job_count).padStart(6)} ` +
          `${(entry.last_trace_id ?? "-").padEnd(22)}`
        );
      }
    }
  }

  console.log(`\nLast updated: ${ledger.last_updated}`);
}

function cmdReset(force: boolean): void {
  if (!force) {
    console.error("ERROR — 'reset' requires --force to prevent accidental clears");
    console.error("Usage: spend-gate reset --force");
    process.exit(1);
  }

  const ledger = readLedger();
  const prevSpend = Object.values(ledger.by_type).reduce((s, e) => s + e.spent_usd, 0);

  ledger.by_type = {};
  ledger.by_agent = {};
  ledger.week_start = getWeekStart();
  writeLedger(ledger);

  console.log(`RESET — ledger cleared (previous total: ${formatUsd(prevSpend)})`);
  console.log(`New week start: ${ledger.week_start}`);
}

// ── Main ──────────────────────────────────────────────────────────

function usage(): void {
  console.log(`spend-gate — Agent fleet spend enforcement

Usage: npx tsx tools/policy/spend-gate.ts <subcommand> [args]

Subcommands:
  check  <agent-type> <estimated-usd>                    Check if spend is allowed
  record <agent-id> <agent-type> <actual-usd>            Record actual spend
         [--trace-id X]
  status [--agent-type X]                                Show budget table
  reset  [--force]                                       Weekly reset

Agent Types: engineer, reviewer, swat, deployer, auditor

Examples:
  spend-gate check engineer 4.50
  spend-gate record x2m-alpha-01 engineer 1.23 --trace-id trc-abc123
  spend-gate status
  spend-gate status --agent-type swat
  spend-gate reset --force`);
}

function main(): void {
  const args = process.argv.slice(2);
  const cmd = args[0];

  if (!cmd || cmd === "--help" || cmd === "-h") {
    usage();
    process.exit(0);
  }

  if (cmd === "check") {
    const agentType = args[1];
    const estimated = parseFloat(args[2] ?? "");
    if (!agentType || isNaN(estimated)) {
      console.error("Usage: spend-gate check <agent-type> <estimated-usd>");
      process.exit(2);
    }
    cmdCheck(agentType, estimated);
    return;
  }

  if (cmd === "record") {
    const agentId = args[1];
    const agentType = args[2];
    const actual = parseFloat(args[3] ?? "");
    if (!agentId || !agentType || isNaN(actual)) {
      console.error("Usage: spend-gate record <agent-id> <agent-type> <actual-usd> [--trace-id X]");
      process.exit(2);
    }
    const traceIdx = args.indexOf("--trace-id");
    const traceId = traceIdx >= 0 ? args[traceIdx + 1] : undefined;
    cmdRecord(agentId, agentType, actual, traceId);
    return;
  }

  if (cmd === "status") {
    const typeIdx = args.indexOf("--agent-type");
    const filterType = typeIdx >= 0 ? args[typeIdx + 1] : undefined;
    cmdStatus(filterType);
    return;
  }

  if (cmd === "reset") {
    const force = args.includes("--force");
    cmdReset(force);
    return;
  }

  console.error(`Unknown subcommand: ${cmd}`);
  usage();
  process.exit(1);
}

main();
