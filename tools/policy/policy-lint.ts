/**
 * tools/policy/policy-lint.ts
 *
 * Nx Target Taxonomy compliance linter.
 * Validates that all projects conform to the canonical target taxonomy
 * defined in nx-targets.contract.json and project-type-mapping.json.
 *
 * Usage:
 *   npx tsx tools/policy/policy-lint.ts
 *   npx tsx tools/policy/policy-lint.ts --verbose
 *   # or via Nx:
 *   pnpm nx run workspace:policy:lint
 */

import fs from "node:fs";
import path from "node:path";
import childProcess from "node:child_process";

// ── Types ────────────────────────────────────────────────────────

interface TargetContract {
  deterministic: boolean;
  cacheable: boolean;
  remoteCacheable: boolean;
  defaultOutputs: string[];
}

interface WorkspaceTargetContract {
  scope: string;
  deterministic: boolean;
  cacheable: boolean;
  remoteCacheable: boolean;
  outputs: string[];
}

interface Contract {
  version: string;
  workspaceTargets: Record<string, WorkspaceTargetContract>;
  projectTargets: Record<string, TargetContract>;
  rules: {
    forbiddenTargetPrefixes: string[];
    requireOutputsForCacheableTargets: boolean;
    requireNoNetworkForDeterministicTargets: boolean;
  };
}

interface ProjectTypeSpec {
  requiredTargets: string[];
  optionalTargets: string[];
}

interface Mapping {
  version: string;
  projectTypes: Record<string, ProjectTypeSpec>;
  classification: {
    sourceOfTruth: string;
    tagPrefix: string;
    examples: string[];
  };
}

interface ReportError {
  project: string;
  issue: string;
  [key: string]: unknown;
}

interface Report {
  contractVersion: string;
  timestamp: string;
  totalProjects: number;
  passedProjects: number;
  failedProjects: number;
  errors: ReportError[];
  warnings: ReportError[];
}

// ── Helpers ──────────────────────────────────────────────────────

const VERBOSE = process.argv.includes("--verbose");

function execJson(cmd: string): unknown {
  try {
    const out = childProcess.execSync(cmd, {
      stdio: ["ignore", "pipe", "pipe"],
      encoding: "utf8",
      timeout: 30_000,
    });
    return JSON.parse(out);
  } catch (err: unknown) {
    const message =
      err instanceof Error ? err.message : String(err);
    console.error(`Failed to execute: ${cmd}`);
    console.error(message);
    process.exit(2);
  }
}

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

// ── Nx project graph helpers ─────────────────────────────────────

function getNxProjectNames(): string[] {
  // Nx 17+ returns a plain array; older versions may return { projects: [...] }
  const result = execJson("pnpm nx show projects --json");
  if (Array.isArray(result)) return result;
  if (
    result !== null &&
    typeof result === "object" &&
    "projects" in result &&
    Array.isArray((result as Record<string, unknown>).projects)
  ) {
    return (result as { projects: string[] }).projects;
  }
  // Nx 16 may return an object keyed by project name
  if (result !== null && typeof result === "object") {
    return Object.keys(result as Record<string, unknown>);
  }
  console.error("Unexpected output from 'nx show projects --json'");
  process.exit(2);
}

interface NxProject {
  tags?: string[];
  targets?: Record<string, { outputs?: string[]; cache?: boolean }>;
}

function getNxProject(name: string): NxProject {
  return execJson(`pnpm nx show project ${name} --json`) as NxProject;
}

// ── Build the set of all recognized target names ─────────────────

function buildRecognizedTargets(
  contract: Contract,
  mapping: Mapping,
): Set<string> {
  const recognized = new Set<string>();
  // Workspace targets
  for (const name of Object.keys(contract.workspaceTargets)) {
    recognized.add(name);
  }
  // Project targets from contract
  for (const name of Object.keys(contract.projectTargets)) {
    recognized.add(name);
  }
  // Quarantine variants are allowed
  for (const name of Object.keys(contract.projectTargets)) {
    if (name.startsWith("test:")) {
      recognized.add(`${name}:quarantine`);
    }
  }
  // All targets referenced in project type mapping
  for (const spec of Object.values(mapping.projectTypes)) {
    for (const t of [...spec.requiredTargets, ...spec.optionalTargets]) {
      recognized.add(t);
    }
  }
  return recognized;
}

// ── Main ─────────────────────────────────────────────────────────

function main(): void {
  const repoRoot = process.cwd();

  const contract = readJson<Contract>(
    path.join(repoRoot, "tools/policy/nx-targets.contract.json"),
  );
  const mapping = readJson<Mapping>(
    path.join(repoRoot, "tools/policy/project-type-mapping.json"),
  );

  const recognizedTargets = buildRecognizedTargets(contract, mapping);
  const projectNames = getNxProjectNames();

  const errors: string[] = [];
  const warnings: string[] = [];
  const report: Report = {
    contractVersion: contract.version,
    timestamp: new Date().toISOString(),
    totalProjects: projectNames.length,
    passedProjects: 0,
    failedProjects: 0,
    errors: [],
    warnings: [],
  };

  const projectErrors = new Set<string>();

  // ── Check 5: Workspace targets exist ─────────────────────────
  // The "workspace" project must have format:check and policy:lint
  const requiredWorkspaceTargets = ["format:check", "policy:lint"];
  const workspaceProj = projectNames.includes("workspace")
    ? getNxProject("workspace")
    : null;

  if (!workspaceProj) {
    const msg = 'No "workspace" project found — required for workspace-level targets';
    errors.push(msg);
    report.errors.push({ project: "workspace", issue: "missing_workspace_project" });
  } else {
    const wsTargets = workspaceProj.targets ?? {};
    for (const required of requiredWorkspaceTargets) {
      if (!wsTargets[required]) {
        const msg = `workspace: missing required workspace target '${required}'`;
        errors.push(msg);
        report.errors.push({
          project: "workspace",
          issue: "missing_workspace_target",
          required,
        });
        projectErrors.add("workspace");
      }
    }
  }

  // ── Per-project checks ───────────────────────────────────────
  for (const projName of projectNames) {
    // Skip the workspace meta-project (validated above)
    if (projName === "workspace") continue;

    const proj = getNxProject(projName);
    const tags: string[] = proj.tags ?? [];
    const typeTags = tags.filter((t) =>
      t.startsWith(mapping.classification.tagPrefix),
    );

    log(`Checking ${projName} (tags: ${tags.join(", ") || "none"})`);

    // Check 1: exactly one type:* tag
    if (typeTags.length !== 1) {
      const msg = `${projName}: must have exactly one type:* tag (found ${typeTags.length}: [${typeTags.join(", ")}])`;
      errors.push(msg);
      report.errors.push({
        project: projName,
        issue: "type_tag_count",
        found: typeTags.length,
        tags: typeTags,
      });
      projectErrors.add(projName);
      continue;
    }

    const projectType = typeTags[0].replace(mapping.classification.tagPrefix, "");
    const typeSpec = mapping.projectTypes[projectType];

    // Check 1b: recognized project type
    if (!typeSpec) {
      const msg = `${projName}: unknown project type '${projectType}' (valid: ${Object.keys(mapping.projectTypes).join(", ")})`;
      errors.push(msg);
      report.errors.push({
        project: projName,
        issue: "unknown_project_type",
        projectType,
        validTypes: Object.keys(mapping.projectTypes),
      });
      projectErrors.add(projName);
      continue;
    }

    const targets = proj.targets ?? {};
    const targetNames = Object.keys(targets);

    // Check 3a: forbidden prefixes
    for (const tn of targetNames) {
      for (const prefix of contract.rules.forbiddenTargetPrefixes) {
        if (tn.startsWith(prefix)) {
          const msg = `${projName}: target '${tn}' uses forbidden prefix '${prefix}'`;
          errors.push(msg);
          report.errors.push({
            project: projName,
            issue: "forbidden_prefix",
            target: tn,
            prefix,
          });
          projectErrors.add(projName);
        }
      }
    }

    // Check 3b: unrecognized targets (no ad-hoc verbs)
    const allAllowed = new Set([
      ...typeSpec.requiredTargets,
      ...typeSpec.optionalTargets,
    ]);
    for (const tn of targetNames) {
      if (!recognizedTargets.has(tn)) {
        const msg = `${projName}: target '${tn}' is not a recognized canonical target`;
        errors.push(msg);
        report.errors.push({
          project: projName,
          issue: "unrecognized_target",
          target: tn,
        });
        projectErrors.add(projName);
      } else if (!allAllowed.has(tn)) {
        // Recognized globally but not allowed for this project type — warn, don't error
        const warnMsg = `${projName}: target '${tn}' is not listed for type '${projectType}' (allowed: ${[...allAllowed].join(", ")})`;
        warnings.push(warnMsg);
        report.warnings.push({
          project: projName,
          issue: "target_not_in_type_mapping",
          target: tn,
          projectType,
        });
      }
    }

    // Check 2: required targets exist
    for (const required of typeSpec.requiredTargets) {
      if (!targets[required]) {
        const msg = `${projName}: missing required target '${required}' for type '${projectType}'`;
        errors.push(msg);
        report.errors.push({
          project: projName,
          issue: "missing_required_target",
          required,
          projectType,
        });
        projectErrors.add(projName);
      }
    }

    // Check 4: cacheable targets have outputs declared
    for (const [tn, tcfg] of Object.entries(targets)) {
      const contractDef = contract.projectTargets[tn];
      if (!contractDef) continue;

      if (
        contractDef.cacheable &&
        contract.rules.requireOutputsForCacheableTargets
      ) {
        const outputs: string[] =
          tcfg.outputs ?? contractDef.defaultOutputs ?? [];
        if (outputs.length === 0) {
          const msg = `${projName}: target '${tn}' is cacheable but has no outputs declared`;
          errors.push(msg);
          report.errors.push({
            project: projName,
            issue: "missing_outputs",
            target: tn,
          });
          projectErrors.add(projName);
        }
      }
    }
  }

  // ── Report ───────────────────────────────────────────────────
  report.failedProjects = projectErrors.size;
  report.passedProjects = report.totalProjects - report.failedProjects;

  const reportDir = path.join(repoRoot, "dist/reports/policy");
  fs.mkdirSync(reportDir, { recursive: true });
  fs.writeFileSync(
    path.join(reportDir, "policy-lint.json"),
    JSON.stringify(report, null, 2),
  );

  console.log(
    `\npolicy:lint — ${report.totalProjects} projects, ${report.passedProjects} passed, ${report.failedProjects} failed`,
  );

  if (warnings.length) {
    console.warn(`\nWarnings (${warnings.length}):`);
    for (const w of warnings) console.warn(`  - ${w}`);
  }

  if (errors.length) {
    console.error(`\nViolations (${errors.length}):`);
    for (const e of errors) console.error(`  - ${e}`);
    console.error(`\nReport: dist/reports/policy/policy-lint.json`);
    process.exit(1);
  }

  console.log("\nAll projects conform to target taxonomy.");
  console.log(`Report: dist/reports/policy/policy-lint.json`);
}

main();
