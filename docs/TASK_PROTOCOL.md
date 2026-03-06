# Task Protocol — Universal Task Envelope

## Purpose

A standardized wire format for every task dispatched across the agent fleet. All orchestrators (develop-cc, coordinator_v3, future systems) speak this format, enabling cross-system trace correlation, spend enforcement, and compliance audit.

## Schema

```
tools/protocol/task-schema.json   — JSON Schema draft-07
tools/protocol/examples/          — Reference task envelopes
tools/protocol/validate-task.ts   — Linter (validates + cross-checks agent-contract.json)
```

## Field Reference

| Field | Required | Description |
|---|---|---|
| `task_id` | ✓ | `task-YYYYMMDD-NNNN` — trace root for telemetry spans |
| `parent_task_id` | | Parent for sub-task fan-out. `null` for root tasks |
| `intent` | ✓ | 10-500 char human description of the task |
| `scope.machine` | ✓ | Target machine name (from `fleet.yaml`) |
| `scope.repo` | | Target repo name (from `fleet.yaml`) |
| `scope.zone` | | x2machines zone ID, e.g. `z02_coordination` |
| `scope.paths` | | Specific file paths in scope. Empty = entire repo |
| `constraints.method` | ✓ | `ssh` \| `codex` \| `claude` \| `local` |
| `constraints.timeout_s` | ✓ | 30-3600 seconds |
| `constraints.budget_usd` | | Max spend. Checked against `agent-contract.json` cap |
| `constraints.trust_tier` | | 0=untrusted, 1=engineer, 2=senior, 3=ops |
| `constraints.agent_type` | | Required agent capability tier |
| `deadline` | | ISO 8601. Task cancelled if not started by deadline |
| `agent_affinity` | | Preferred agent IDs. Scheduler uses best-effort |
| `priority` | | 0=lowest, 5=highest (SWAT). Feeds ICP intent vector |
| `metadata.linear_id` | | Linear issue ID for sync |
| `metadata.icp_admission_id` | | Links to ICP feedback loop |
| `metadata.parent_job_id` | | develop-cc Job ID of parent |
| `metadata.batch_id` | | Groups fan-out sub-tasks |

## develop-cc Job Mapping

How `develop_cc/engines/dispatch.py` maps a `Job` to a `TaskEnvelope`:

```python
# develop_cc/engines/dispatch.py — proposed integration
task = TaskEnvelope(
    task_id=f"task-{job.dispatched_at:%Y%m%d}-{seq:04d}",
    parent_task_id=None,
    intent=job.command[:500],
    scope=Scope(
        machine=job.machine,
        repo=job.repo,
        zone=extract_zone(job.command),      # regex: z\d{2}_[a-z_]+
    ),
    constraints=Constraints(
        method=job.method,
        timeout_s=timeout,
        budget_usd=None,                     # filled by spend-gate.check()
        trust_tier=ZONE_TRUST_MAP.get(zone, 1),
        agent_type=ZONE_ROLE_MAP.get(zone, "engineer"),
    ),
    priority=5 if job.profile.startswith("swat:") else 2,
    metadata=Metadata(
        icp_admission_id=job.icp_admission_id,
        parent_job_id=job.id,
        linear_id=extract_linear_id(job.command),
    ),
)
```

## Trace ID as Root

The `task_id` is the trace root. All telemetry spans reference it:

```
task-20260305-0001   ← root
├─ span: icp_admission  (trace_id=task-20260305-0001, span_id=adm-001)
├─ span: job_dispatch   (trace_id=task-20260305-0001, span_id=dsp-001)
│   └─ span: gate_check W0  (parent_span_id=dsp-001)
│   └─ span: gate_check W1  (parent_span_id=dsp-001)
├─ span: cost_incurred  (trace_id=task-20260305-0001)
└─ span: swat_escalation (trace_id=task-20260305-0001, parent=task-20260305-0001)
    └─ task-20260305-0042  ← SWAT sub-task, parent_task_id=task-20260305-0001
```

## Batch Fan-Out

`batch.py` constructs one envelope per sub-task, all sharing the same `batch_id`:

```python
tasks = [
    TaskEnvelope(task_id=f"task-{date}-{i:04d}", parent_task_id=root_task_id,
                 metadata=Metadata(batch_id=batch_id), ...)
    for i, (machine, repo, command) in enumerate(fan_out_targets)
]
```

## Priority → ICP Mapping

| Priority | Meaning | ICP optionality_preservation |
|---|---|---|
| 5 | SWAT (critical failure) | 0.95 |
| 4 | Blocked dependency | 0.85 |
| 3 | Deploy / release | 0.75 |
| 2 | Normal engineering (default) | 0.50 |
| 1 | Background / housekeeping | 0.30 |
| 0 | Audit / read-only | 0.10 |

## Validation

```bash
npx tsx tools/protocol/validate-task.ts --all-examples
npx tsx tools/protocol/validate-task.ts path/to/my-task.json
```

Validator cross-checks:
- `budget_usd` ≤ agent type `spend_cap_usd` from `agent-contract.json`
- `budget_usd` ≤ global `maxSpendPerJobUsd`
- `method` ∈ agent type `allowed_methods`
- `timeout_s` ≤ agent type `max_ttl_seconds`
