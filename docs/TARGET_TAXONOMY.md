# Nx Target Taxonomy + Progressive Gates (Policy)

## Mission
Define a canonical target taxonomy for a polyglot Nx monorepo (Node/TS, Python/Cython, Rust)
with progressive CI gates that tighten as release criticality increases.

This document is normative: teams MUST NOT invent new verbs without updating this policy and
the contracts in `tools/policy/nx-targets.contract.json`.

---

## Goals
- Deterministic, cacheable builds with Nx remote caching.
- Progressive gates: frequency and strictness increase from DEV → STABILIZATION → RELEASE.
- Polyglot parity: the same targets exist across languages with language-appropriate implementations.
- Build-once promote-many: immutable artifacts + provenance.

## Non-goals (for now)
- Full SLSA Level 3+ requirements, SBOM everywhere, and enterprise policy engines.

---

## Canonical Targets (verbs)

### Workspace-level targets
These run at the repo root or orchestrate across multiple projects:
- format:check
- format:write
- security:deps (optional workspace)
- policy:lint (required workspace)

### Project-level targets (core)
Required where applicable (see Project Type Mapping):
- lint
- typecheck
- test:unit
- build
- package (required for deployables; optional for internal libs)

### Project-level targets (integration/system)
Only for projects that need them:
- test:integration
- test:e2e
- docker:build
- docker:scan
- migrate:check
- contract:check

---

## Target Semantics (meaning)

### lint
Static linting only. No network calls. Deterministic. Produces reports under `dist/reports/lint/`.

### typecheck
Type checking only. No code emit. No network calls. Deterministic. Produces reports under `dist/reports/typecheck/`.

### test:unit
Fast tests only (no external services required). Deterministic. Produces `dist/reports/tests/unit/`.

### build
Compile/transpile/package to local build output.
- Node: dist/ output
- Python/Cython: wheel build output (or build artifacts)
- Rust: target/ output
Produces `dist/` (or equivalent language-native output) and optional build metadata.

### package
Creates an immutable artifact suitable for deployment/promotion. Must be reproducible from the same inputs.
Uploads to artifact store in CI Release mode. Produces `dist/artifacts/...` locally (optional).

### test:integration
May require services (DB, queues). Prefer deterministic but allowed to be environment-dependent.
Must not run in untrusted lanes with secrets. Produces `dist/reports/tests/integration/`.

### test:e2e
System tests. Environment-dependent. Never cached. Runs only in Trusted lane. Produces `dist/reports/tests/e2e/`.

### docker:build
Build container image(s). Prefer deterministic via pinned base image digests. Uses registry layer cache. Produces image digest output.

### docker:scan
Container scanning. Deterministic scanner runs only. Produces `dist/reports/security/container/`.

### migrate:check
Validates migrations apply cleanly (dry-run where possible). Produces `dist/reports/migrations/`.

### contract:check
Validates backward compatibility for APIs/events/schemas. Produces `dist/reports/contracts/`.

### policy:lint (workspace)
Validates every Nx project matches required target taxonomy + caching/output constraints.

---

## Cache Policy (default)

| Target | Cacheable | Nx Remote Cache | Notes |
|---|---:|---:|---|
| lint | Yes | Yes | Must be deterministic |
| typecheck | Yes | Yes | Must be deterministic |
| test:unit | Yes | Yes | Flaky tests must be quarantined |
| build | Yes | Yes | Deterministic toolchain required |
| package | Yes | Yes | Immutable artifact required in RELEASE |
| test:integration | Partial | Usually No | Often environment-dependent |
| test:e2e | No | No | Never cached |
| docker:build | Partial | N/A | Use registry layer cache |
| docker:scan | No/Partial | No | Deterministic scanners only |
| migrate:check | No/Partial | No | Env dependent |
| contract:check | Yes | Yes | Deterministic |

---

## Progressive Gates

### Trust Lanes
- **Untrusted lane** (PRs from forks / unknown branches): no secrets, no deploy.
- **Trusted lane** (main/release/approved): secrets allowed, heavy builds allowed, deploy allowed by environment.

### Release Modes
- **DEV**
- **STABILIZATION**
- **RELEASE**

### Runner Tiers
- **Tier-2**: GitHub-hosted (fast + stable): lint/typecheck/test:unit on affected
- **Tier-3**: Self-hosted ephemeral (heavy builds): build/package/test:integration where safe
- **Tier-4**: Self-hosted controlled env: e2e + release packaging + provenance

### Gate Matrix

**Always blocking on PRs (all modes):**
- format:check
- policy:lint
- nx affected -t lint,typecheck,test:unit

**DEV:**
- build/test:integration: non-blocking on PR; required nightly
- e2e/system: nightly only; non-blocking

**STABILIZATION:**
- build/test:integration: runs on PR; becomes blocking when stable (>=95% pass over last 50)
- e2e smoke: blocking; full e2e: non-blocking until stable

**RELEASE:**
- build/package/test:integration: blocking
- e2e: blocking on release branches/tags
- provenance + artifact upload: blocking

---

## Flake Quarantine
If any test target is flaky:
- move it to `test:unit:quarantine` or `test:integration:quarantine`
- quarantine targets never block merges
- must have an owner + SLA to restore stability

---

## Promotion Rule (blocking eligibility)
A check becomes blocking only if:
- Pass rate >=95% over last 50 runs in Trusted lane
- Median runtime within agreed threshold
If stability drops, demote automatically to non-blocking.

---

## Language Mapping (how each stack implements targets)

### Node/TS projects
- lint → eslint
- typecheck → tsc -p ... --noEmit
- test:unit → vitest/jest
- build → bundler/tsc emit
- package → build + package bundle

### Python/Cython projects
- lint → ruff (or flake8)
- typecheck → mypy/pyright
- test:unit → pytest (unit marker)
- build → build wheel / compile cython extensions
- package → build wheel(s) + publish to artifact store

### Rust projects
- lint → clippy
- typecheck → cargo check
- test:unit → cargo test (unit)
- build → cargo build --release (or per profile)
- package → tarball/bin + checksums

**Policy:** all compilers use pinned toolchain images and their cache systems:
- Rust uses sccache
- Python uses shared wheelhouse cache
- Node uses pnpm store
- Nx uses remote cache via MinIO/S3

---

## Deterministic Toolchain Pinning

### Runner images (pinned OCI)
- `ci-node:<ver>` (Node + pnpm pinned)
- `ci-python:<ver>` (Python + pip/build tooling pinned; manylinux if shipping wheels)
- `ci-rust:<ver>` (rustup toolchain pinned; LLVM/Clang pinned if needed)
- `ci-polyglot:<ver>` (combined; higher drift risk)

### Repo-level pins (enforced)
- Node version (.nvmrc or volta), pnpm version (Corepack)
- Python version (pyproject/uv/asdf) + pinned build deps
- Rust toolchain via rust-toolchain.toml
- Base Docker images pinned by digest for release builds

**Enforcement:** CI fails if toolchain version differs from pinned spec.

---

## Cache Correctness Contract

### Nx remote cache key MUST include
- Nx version
- project graph hash
- target name + options
- relevant inputs (files, tsconfig, env)
- OS/arch
- toolchain versions via environment fingerprint

### Rust (sccache) key MUST include
- rustc version + target triple
- compiler flags (RUSTFLAGS)
- relevant env vars
- source hash

### Python wheel cache MUST include
- Python version
- platform tag (manylinux/macos)
- compiler/libc versions for native deps (Cython)
- dependency lock/constraints hash

### pnpm store correctness
- pnpm version pinned
- lockfile hash included
- store path isolated per pnpm major

### Docker registry cache
- base images pinned (digest for release)
- build args included in cache key
- registry supports layer caching

**Cache escape hatch:** per-job `CACHE_BYPASS=1` and automated cache-bust on toolchain bump PRs.

---

## Forbidden Target Prefixes

The following target name prefixes are **forbidden** and will fail policy:lint:
- `ci:` — CI-specific targets belong in workflows, not the Nx graph
- `tmp:` — temporary/experimental targets must not enter the graph
- `scratch:` — same as tmp; use feature branches instead

If you need a new canonical target, add it to `tools/policy/nx-targets.contract.json`
and `tools/policy/project-type-mapping.json`, then update this document.

---

## Build-Once Promote-Many (artifact model)

### Artifact store
- S3/MinIO bucket: `artifacts/<repo>/<sha>/<component>/<artifact>`
- Bucket versioning enabled
- Lifecycle retention policies

### Promotion model
- Build artifacts once (Trusted lane) → store immutable outputs
- Staging/prod deploy jobs pull artifacts (by SHA/tag), do not rebuild
- Release manifest (JSON) lists: git SHA, artifact digests, toolchain image digests

### Release provenance (minimum viable)
**Must-have:**
- Signed git tags for releases
- Build metadata artifact: SHA, branch, workflow run ID, runner image digests, lockfile hashes, artifact digests

**Optional (recommended soon):**
- Attestations (supply-chain) for release artifacts
