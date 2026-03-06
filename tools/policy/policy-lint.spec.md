# policy:lint — Nx Target Taxonomy Compliance

## Purpose
Fail CI if projects do not conform to the canonical target taxonomy and target contracts.

## Inputs
- Nx project graph metadata (`nx show projects --json` or Nx project configuration)
- `tools/policy/nx-targets.contract.json`
- `tools/policy/project-type-mapping.json`

## Classification
Each Nx project MUST have at least one tag of the form `type:<projectType>` that exists in `project-type-mapping.json`.

## Checks
1. Each project has exactly one recognized `type:*` tag.
2. Required targets exist for that project type.
3. Targets use canonical names (no forbidden prefixes; no ad-hoc verbs).
4. For each cacheable target:
   - `outputs` are declared (or defaultOutputs applied)
   - deterministic targets do not declare network dependencies (best-effort heuristic)
5. For workspace targets:
   - `format:check`, `policy:lint` exist and are runnable

## Output
- JSON report: `dist/reports/policy/policy-lint.json`
- Console summary and non-zero exit on violations
