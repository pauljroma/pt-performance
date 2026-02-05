# Codebase Assessment (PT Performance)

Date: 2026-02-05
Scope reviewed: `agent-service/` backend and top-level repository structure.

## Executive Summary

The repository appears to be documentation-heavy with one active backend service (`agent-service`) implementing patient summaries, PT assistant logic, flags, and therapist dashboards. Core behavior is working and tests pass, but maintainability and production-readiness risks remain around architecture drift, auth/security boundaries, and data-access performance.

## What Looks Good

1. **Clear service decomposition in backend**
   - Domain behavior is split into `services/` modules (`assistant`, `supabase`, `therapist`, `flags`, `protocol-validator`) and route files.
2. **Basic environment validation exists**
   - Required env vars are validated early in `config.js`, preventing silent boot failures.
3. **Risk-aware PT logic and tests**
   - Assistant logic encodes conservative safety behavior and has corresponding unit tests.
4. **Pragmatic local fallback path**
   - Supabase service has mock-data fallback behavior for demo/local operation.

## Key Risks and Gaps

### 1) Architectural drift and duplicated server entrypoints
- `src/server.js` appears to be the active runtime entrypoint (`package.json` points to it), while `src/server-updated.js` contains another partial server implementation.
- Keeping parallel entrypoints increases confusion and regression risk during future edits.

### 2) Missing authentication/authorization at API edge
- Therapist routes accept `:therapistId` but do not enforce identity checks in middleware.
- This is a critical production risk: callers can request other therapists' data by changing path params.

### 3) Data-access scalability concerns (N+1 patterns)
- `services/therapist.js` enriches each patient with additional per-patient queries (adherence + last session), creating N+1 query behavior.
- This will degrade linearly as patient counts increase.

### 4) Inconsistent error handling contract
- Route handlers generally return broad `500` responses with raw `error.message`.
- Error shapes differ by endpoint and may leak backend internals to clients.

### 5) Logging middleware not universally applied
- `middleware/logging.js` exists with rich request/response logging, but current `server.js` does not register it.
- Observability will be inconsistent unless middleware integration is standardized.

### 6) Repository hygiene and ownership clarity
- Large volume of historical markdown artifacts and generated reports at repo root makes it hard to identify source-of-truth docs and active code paths quickly.

## Priority Recommendations

1. **Consolidate server entrypoints (P0)**
   - Pick one server bootstrap file (`server.js`) and remove/archive `server-updated.js` after merging any missing functionality.
2. **Add authn/authz middleware before therapist routes (P0)**
   - Require verified user identity and enforce therapist-to-patient ownership checks.
3. **Eliminate N+1 therapist queries (P1)**
   - Replace per-patient fetches with a single SQL view or batched query strategy.
4. **Standardize API errors (P1)**
   - Introduce a shared error helper and a global error middleware returning stable error codes.
5. **Enable logging middleware in main server (P1)**
   - Wire `loggingMiddleware` and `errorLoggingMiddleware` into `server.js`; define payload redaction policy centrally.
6. **Repo cleanup and structure (P2)**
   - Move completion reports and one-off docs into `docs/archive/`; keep root focused on active runtime code and onboarding docs.

## Validation Performed

- Ran unit tests in `agent-service`:
  - `npm test -- --runInBand` ✅ (23 tests passed)

## Suggested Next 2-Week Plan

- Week 1: auth middleware + server consolidation + standardized error model.
- Week 2: therapist query optimization + observability integration + doc/archive cleanup.

