# gate-promote — Flake Quarantine + Promotion Spec

## Purpose

Automates the flake quarantine lifecycle defined in TARGET_TAXONOMY.md:
- Tests that drop below 95% pass rate over 50 runs are quarantined
- Quarantined tests are promoted back when they reach 95% over 50 consecutive runs
- A quarantine manifest is generated for CI to skip known-flaky tests

## Commands

### `record <results-file>`

Parse test results (Jest JSON or pytest JUnit XML) and update the sliding window.

- Detects format automatically (.xml → pytest, .json → Jest)
- Maintains a circular buffer of the last `window_size` results per test
- Auto-quarantines any active test that drops below `quarantine_below` threshold
- Minimum 10 results before quarantine triggers (prevents false positives on new tests)

### `status`

Display all quarantined tests with pass rate, run count, and quarantine date.

### `promote [--dry-run]`

Evaluate quarantined tests for promotion back to active status.

- Requires full `window_size` results at or above `promote_above` threshold
- `--dry-run` shows eligible tests without changing state

### `quarantine`

Generate `dist/reports/policy/quarantine.json` manifest listing all quarantined tests.
This file is consumed by CI to exclude flaky tests from blocking gates.

## State

- `tools/policy/.state/gate-history.json` — Per-test result windows (gitignored)
- `dist/reports/policy/quarantine.json` — Generated manifest (cacheable)

## Configuration

`tools/policy/gate-contract.json`:
- `thresholds.quarantine_below` — Auto-quarantine threshold (default: 0.95)
- `thresholds.promote_above` — Auto-promote threshold (default: 0.95)
- `thresholds.window_size` — Sliding window size (default: 50)

## Integration

- Runs in nightly CI after test suites complete
- Quarantine manifest consumed by `policy-lint` (warning, not error)
- Workspace target: `pnpm nx run workspace:gate:promote`
