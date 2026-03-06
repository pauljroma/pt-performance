# Hook Library — Catalog

Reusable Claude Code `PreToolUse` / `PostToolUse` hooks for the agent fleet.
Each hook is a standalone bash script reading `HOOK_INPUT` (JSON piped from Claude Code).
Exit 0 = allow, exit 1 = block.

## Quick Start

```bash
# Generate settings.json for your project
./hooks/compose-hooks.sh lint-on-save block-dangerous-commands block-regulated-paths > .claude/settings.json
```

## Hook Catalog

| Hook | Trigger | Matcher | Purpose |
|------|---------|---------|---------|
| `lint-on-save` | PostToolUse | `Edit\|Write` | Run linter after file edits |
| `block-regulated-paths` | PreToolUse | `Edit\|Write\|Bash` | Block writes to sensitive paths |
| `block-dangerous-commands` | PreToolUse | `Bash` | Block `rm -rf`, force push, `DROP TABLE` |
| `cost-check` | PreToolUse | `Bash` | Check spend-gate budget before dispatch |
| `audit-log` | PostToolUse | `Edit\|Write\|Bash\|Agent` | Append to compliance audit trail |
| `gate-check` | PreToolUse | `Agent\|Write` | W0 gate + trust tier enforcement |

---

## Hook Reference

### `lint-on-save.sh`
- **Trigger**: PostToolUse
- **Matcher**: `Edit|Write`
- **Env vars**:
  - `LINT_CMD` — linter command (default: `npx eslint --fix`)
- **Behavior**: Runs linter on the edited file. Non-blocking (lint failures are warnings).

### `block-regulated-paths.sh`
- **Trigger**: PreToolUse
- **Matcher**: `Edit|Write|Bash`
- **Env vars**:
  - `REGULATED_PATHS` — colon-separated path patterns (default: `migrations/:clinical-rules/:.env:secrets/:audit_log/:infra/prod/:certs/`)
- **Behavior**: Blocks any tool call touching a regulated path. Exit 1 = blocked.

### `block-dangerous-commands.sh`
- **Trigger**: PreToolUse
- **Matcher**: `Bash`
- **Env vars**:
  - `ALLOW_FORCE_PUSH=1` — permit `git push --force` on non-main branches
- **Behavior**: Blocks patterns:
  - `rm -rf` / `rm --recursive --force`
  - `git push --force` to `main`/`master`/`production`
  - `git reset --hard HEAD~N` (multi-commit rewind)
  - `DROP TABLE/DATABASE/SCHEMA` (without IF EXISTS)
  - `TRUNCATE TABLE`
  - Credential exposure (`cat .env`, `printenv KEY`, etc.)
  - `mkfs.`, `dd if=...of=/dev/`

### `cost-check.sh`
- **Trigger**: PreToolUse
- **Matcher**: `Bash`
- **Env vars**:
  - `AGENT_TYPE` — required; skipped if not set
  - `ESTIMATED_USD` — estimated cost for this job (default: 0.0)
  - `SPEND_GATE_CMD` — path to `spend-gate.ts` runner (auto-detected if not set)
- **Behavior**: Calls `spend-gate check <agent-type> <estimated-usd>`. Blocks on cap exceeded.

### `audit-log.sh`
- **Trigger**: PostToolUse
- **Matcher**: `Edit|Write|Bash|Agent`
- **Env vars**:
  - `AGENT_ID` — required; used as filename in audit trail
  - `MACHINE` — machine name (default: `hostname -s`)
  - `TRACE_ID` — propagated trace ID (default: `trc-unknown`)
  - `AUDIT_REPLAY_CMD` — path to `replay.ts` runner (optional; falls back to direct write)
- **Behavior**: Appends event JSON to `dist/audit/{date}/{agent_id}.ndjson`.

### `gate-check.sh`
- **Trigger**: PreToolUse
- **Matcher**: `Agent|Write`
- **Env vars**:
  - `GATE_STAGE` — gate level (default: `W0`)
  - `GATE_THRESHOLD` — TC score threshold (default: `0.64`)
  - `TC_SCORE_CMD` — command returning a float TC score (optional)
  - `AGENT_TRUST_TIER` — current agent trust tier (default: `1`)
  - `REQUIRED_TRUST_TIER` — minimum required (default: `0`)
- **Behavior**: Blocks if TC score < threshold or agent trust tier < required.

---

## `compose-hooks.sh`

Generates a `.claude/settings.json` from a selection of hooks:

```bash
./hooks/compose-hooks.sh <hook1> [hook2...] > .claude/settings.json
```

**Example output** for `compose-hooks.sh lint-on-save block-dangerous-commands`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [{"type": "command", "command": "HOOK_INPUT=$(cat) /path/to/block-dangerous-commands.sh"}]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [{"type": "command", "command": "HOOK_INPUT=$(cat) /path/to/lint-on-save.sh"}]
      }
    ]
  }
}
```

---

## Enterprise Stack (recommended for x2m agents)

```bash
# Full enforcement: audit + cost + safety + gate
./hooks/compose-hooks.sh \
  block-dangerous-commands \
  block-regulated-paths \
  cost-check \
  gate-check \
  audit-log \
  > .claude/settings.json
```

Set environment variables per-agent in the coordinator config:

```yaml
env:
  AGENT_ID: x2m-alpha-engineer
  AGENT_TYPE: engineer
  MACHINE: x2machines
  TRACE_ID: "${task_id}"
  AGENT_TRUST_TIER: "1"
  REQUIRED_TRUST_TIER: "1"
  GATE_STAGE: W1
  GATE_THRESHOLD: "0.64"
```
