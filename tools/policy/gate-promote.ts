/**
 * tools/policy/gate-promote.ts
 *
 * Flake quarantine and promotion engine.
 * Tracks test pass rates over a sliding window and auto-quarantines
 * flaky tests (below threshold) and promotes them back when stable.
 *
 * Usage:
 *   npx tsx tools/policy/gate-promote.ts record <results-file>
 *   npx tsx tools/policy/gate-promote.ts status
 *   npx tsx tools/policy/gate-promote.ts promote [--check] [--dry-run]
 *   npx tsx tools/policy/gate-promote.ts quarantine
 */

import fs from "node:fs";
import path from "node:path";

// ── Types ────────────────────────────────────────────────────────

interface GateContract {
  version: string;
  thresholds: {
    quarantine_below: number;
    promote_above: number;
    window_size: number;
  };
  report_formats: Record<
    string,
    { glob: string; parser: string }
  >;
}

interface TestEntry {
  results: boolean[];
  pass_rate: number;
  status: "active" | "quarantined";
  quarantined_at: string | null;
  promoted_at: string | null;
}

interface GateHistory {
  tests: Record<string, TestEntry>;
  last_updated: string;
}

interface JestTestResult {
  fullName?: string;
  title?: string;
  status?: string;
}

interface JestSuiteResult {
  testResults?: JestTestResult[];
}

interface JestReport {
  testResults?: JestSuiteResult[];
}

// ── Helpers ──────────────────────────────────────────────────────

function readJson<T>(filePath: string): T {
  if (!fs.existsSync(filePath)) {
    console.error(`File not found: ${filePath}`);
    process.exit(2);
  }
  return JSON.parse(fs.readFileSync(filePath, "utf8")) as T;
}

const REPO_ROOT = process.cwd();
const CONTRACT_PATH = path.join(REPO_ROOT, "tools/policy/gate-contract.json");
const STATE_DIR = path.join(REPO_ROOT, "tools/policy/.state");
const HISTORY_PATH = path.join(STATE_DIR, "gate-history.json");
const QUARANTINE_PATH = path.join(
  REPO_ROOT,
  "dist/reports/policy/quarantine.json",
);

function ensureState(): void {
  fs.mkdirSync(STATE_DIR, { recursive: true });
  if (!fs.existsSync(HISTORY_PATH)) {
    const initial: GateHistory = { tests: {}, last_updated: "" };
    fs.writeFileSync(HISTORY_PATH, JSON.stringify(initial, null, 2));
  }
}

function loadHistory(): GateHistory {
  ensureState();
  return readJson<GateHistory>(HISTORY_PATH);
}

function saveHistory(history: GateHistory): void {
  history.last_updated = new Date().toISOString();
  fs.writeFileSync(HISTORY_PATH, JSON.stringify(history, null, 2));
}

function computePassRate(results: boolean[]): number {
  if (results.length === 0) return 1.0;
  const passed = results.filter(Boolean).length;
  return passed / results.length;
}

// ── Parsers ──────────────────────────────────────────────────────

function parseJestResults(
  filePath: string,
): Array<{ name: string; passed: boolean }> {
  const report = readJson<JestReport>(filePath);
  const results: Array<{ name: string; passed: boolean }> = [];

  if (!report.testResults) return results;

  for (const suite of report.testResults) {
    if (!suite.testResults) continue;
    for (const test of suite.testResults) {
      const name = test.fullName ?? test.title ?? "unknown";
      results.push({ name, passed: test.status === "passed" });
    }
  }
  return results;
}

function parsePytestJunit(
  filePath: string,
): Array<{ name: string; passed: boolean }> {
  const content = fs.readFileSync(filePath, "utf8");
  const results: Array<{ name: string; passed: boolean }> = [];

  // Simple regex parsing for JUnit XML (no external dependency)
  const testcaseRegex =
    /<testcase\s+[^>]*name="([^"]*)"[^>]*classname="([^"]*)"[^>]*>([\s\S]*?)<\/testcase>/g;
  const selfClosingRegex =
    /<testcase\s+[^>]*name="([^"]*)"[^>]*classname="([^"]*)"[^/]*\/>/g;

  let match: RegExpExecArray | null;

  while ((match = testcaseRegex.exec(content)) !== null) {
    const name = `${match[2]}::${match[1]}`;
    const body = match[3];
    const passed = !/<failure/i.test(body) && !/<error/i.test(body);
    results.push({ name, passed });
  }

  while ((match = selfClosingRegex.exec(content)) !== null) {
    const name = `${match[2]}::${match[1]}`;
    results.push({ name, passed: true });
  }

  return results;
}

function detectFormat(
  filePath: string,
): "jest" | "pytest" {
  if (filePath.endsWith(".xml")) return "pytest";
  // Try to detect from content
  const content = fs.readFileSync(filePath, "utf8").slice(0, 200);
  if (content.includes("<testsuites") || content.includes("<testsuite")) {
    return "pytest";
  }
  return "jest";
}

// ── Commands ─────────────────────────────────────────────────────

function cmdRecord(resultsFile: string): void {
  const contract = readJson<GateContract>(CONTRACT_PATH);
  const history = loadHistory();
  const windowSize = contract.thresholds.window_size;
  const quarantineThreshold = contract.thresholds.quarantine_below;

  const format = detectFormat(resultsFile);
  const testResults =
    format === "jest"
      ? parseJestResults(resultsFile)
      : parsePytestJunit(resultsFile);

  if (testResults.length === 0) {
    console.log("No test results found in file.");
    return;
  }

  let recorded = 0;
  let newQuarantines = 0;

  for (const { name, passed } of testResults) {
    if (!history.tests[name]) {
      history.tests[name] = {
        results: [],
        pass_rate: 1.0,
        status: "active",
        quarantined_at: null,
        promoted_at: null,
      };
    }

    const entry = history.tests[name];
    entry.results.push(passed);

    // Trim to window size
    if (entry.results.length > windowSize) {
      entry.results = entry.results.slice(entry.results.length - windowSize);
    }

    entry.pass_rate = computePassRate(entry.results);
    recorded++;

    // Auto-quarantine if below threshold and has enough data
    if (
      entry.status === "active" &&
      entry.results.length >= 10 &&
      entry.pass_rate < quarantineThreshold
    ) {
      entry.status = "quarantined";
      entry.quarantined_at = new Date().toISOString();
      newQuarantines++;
      console.log(
        `  QUARANTINE ${name} (pass rate: ${(entry.pass_rate * 100).toFixed(1)}%)`,
      );
    }
  }

  saveHistory(history);

  const totalQuarantined = Object.values(history.tests).filter(
    (t) => t.status === "quarantined",
  ).length;
  console.log(
    `\nRecorded ${recorded} test results. ${newQuarantines} newly quarantined. ${totalQuarantined} total quarantined.`,
  );
}

function cmdStatus(): void {
  const history = loadHistory();

  const quarantined = Object.entries(history.tests).filter(
    ([, t]) => t.status === "quarantined",
  );

  if (quarantined.length === 0) {
    console.log("No quarantined tests.");
    return;
  }

  console.log(`\nQuarantined tests (${quarantined.length}):\n`);
  console.log(
    `${"TEST".padEnd(60)} ${"PASS RATE".padEnd(10)} ${"RUNS".padEnd(6)} ${"SINCE".padEnd(12)}`,
  );
  console.log(
    `${"---".padEnd(60)} ${"---".padEnd(10)} ${"---".padEnd(6)} ${"---".padEnd(12)}`,
  );

  for (const [name, entry] of quarantined) {
    const displayName =
      name.length > 58 ? name.slice(0, 55) + "..." : name;
    const rate = `${(entry.pass_rate * 100).toFixed(1)}%`;
    const runs = String(entry.results.length);
    const since = entry.quarantined_at
      ? entry.quarantined_at.slice(0, 10)
      : "-";
    console.log(
      `${displayName.padEnd(60)} ${rate.padEnd(10)} ${runs.padEnd(6)} ${since.padEnd(12)}`,
    );
  }
}

function cmdPromote(dryRun: boolean): void {
  const contract = readJson<GateContract>(CONTRACT_PATH);
  const history = loadHistory();
  const promoteThreshold = contract.thresholds.promote_above;
  const windowSize = contract.thresholds.window_size;

  const quarantined = Object.entries(history.tests).filter(
    ([, t]) => t.status === "quarantined",
  );

  if (quarantined.length === 0) {
    console.log("No quarantined tests to evaluate.");
    return;
  }

  let promoted = 0;

  for (const [name, entry] of quarantined) {
    if (
      entry.results.length >= windowSize &&
      entry.pass_rate >= promoteThreshold
    ) {
      if (dryRun) {
        console.log(
          `  WOULD PROMOTE ${name} (pass rate: ${(entry.pass_rate * 100).toFixed(1)}%)`,
        );
      } else {
        entry.status = "active";
        entry.promoted_at = new Date().toISOString();
        console.log(
          `  PROMOTED ${name} (pass rate: ${(entry.pass_rate * 100).toFixed(1)}%)`,
        );
      }
      promoted++;
    }
  }

  if (!dryRun && promoted > 0) {
    saveHistory(history);
  }

  console.log(
    `\n${promoted} tests ${dryRun ? "eligible for" : ""} promotion.`,
  );
}

function cmdQuarantine(): void {
  const history = loadHistory();

  const quarantined = Object.entries(history.tests)
    .filter(([, t]) => t.status === "quarantined")
    .map(([name, entry]) => ({
      test: name,
      pass_rate: entry.pass_rate,
      runs: entry.results.length,
      quarantined_at: entry.quarantined_at,
    }));

  const reportDir = path.join(REPO_ROOT, "dist/reports/policy");
  fs.mkdirSync(reportDir, { recursive: true });
  fs.writeFileSync(
    QUARANTINE_PATH,
    JSON.stringify(
      {
        timestamp: new Date().toISOString(),
        total_quarantined: quarantined.length,
        tests: quarantined,
      },
      null,
      2,
    ),
  );

  console.log(
    `Quarantine manifest: ${quarantined.length} tests → dist/reports/policy/quarantine.json`,
  );
}

// ── Main ─────────────────────────────────────────────────────────

function main(): void {
  const args = process.argv.slice(2);
  const cmd = args[0];

  if (!cmd || cmd === "--help" || cmd === "-h") {
    console.log(`gate-promote — Flake quarantine and promotion engine

Usage:
  npx tsx tools/policy/gate-promote.ts record <results-file>
  npx tsx tools/policy/gate-promote.ts status
  npx tsx tools/policy/gate-promote.ts promote [--dry-run]
  npx tsx tools/policy/gate-promote.ts quarantine

Thresholds (from gate-contract.json):
  quarantine_below: ${95}%  (auto-quarantine when pass rate drops below)
  promote_above:    ${95}%  (auto-promote when pass rate recovers to)
  window_size:      ${50}   (sliding window of recent runs)`);
    return;
  }

  switch (cmd) {
    case "record": {
      const file = args[1];
      if (!file) {
        console.error("Usage: gate-promote.ts record <results-file>");
        process.exit(2);
      }
      cmdRecord(file);
      break;
    }
    case "status":
      cmdStatus();
      break;
    case "promote":
      cmdPromote(args.includes("--dry-run"));
      break;
    case "quarantine":
      cmdQuarantine();
      break;
    default:
      console.error(`Unknown command: ${cmd}`);
      process.exit(1);
  }
}

main();
