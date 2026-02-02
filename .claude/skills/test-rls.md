# Test RLS Policies

Verify Row Level Security policies work correctly for a table.

## Trigger

```
/test-rls [table-name]
```

**Examples:**
- `/test-rls patients` - Test patients table RLS
- `/test-rls sessions` - Test sessions table RLS
- `/test-rls --all` - Test all tables with RLS

## Prerequisites

1. Supabase project with RLS enabled
2. Test user accounts (patient, therapist roles)
3. Supabase CLI or Dashboard access

## Execution Steps

### Phase 1: Identify Table Policies

```sql
-- List all policies for a table
SELECT
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE tablename = '[table-name]';
```

### Phase 2: Test as Anonymous User

```bash
# Should fail (RLS blocks anonymous)
curl "https://rpbxeaxlaoyoqkohytlw.supabase.co/rest/v1/[table]" \
  -H "apikey: [ANON_KEY]" \
  -H "Authorization: Bearer [ANON_KEY]"

# Expected: 401 or empty array
```

### Phase 3: Test as Patient

```sql
-- Impersonate patient role
SET LOCAL ROLE authenticated;
SET LOCAL request.jwt.claims = '{"sub": "[patient-uuid]", "role": "patient"}';

-- Test SELECT (should only see own data)
SELECT * FROM [table] LIMIT 10;

-- Test INSERT (should work for own records)
INSERT INTO [table] (patient_id, ...) VALUES ('[patient-uuid]', ...);

-- Test UPDATE (should only update own records)
UPDATE [table] SET ... WHERE patient_id = '[patient-uuid]';

-- Test cross-patient access (should fail)
SELECT * FROM [table] WHERE patient_id = '[other-patient-uuid]';
```

### Phase 4: Test as Therapist

```sql
-- Impersonate therapist role
SET LOCAL ROLE authenticated;
SET LOCAL request.jwt.claims = '{"sub": "[therapist-uuid]", "role": "therapist"}';

-- Test SELECT (should see linked patients)
SELECT * FROM [table] WHERE patient_id IN (
  SELECT patient_id FROM therapist_patients
  WHERE therapist_id = '[therapist-uuid]'
);

-- Test access to unlinked patient (should fail)
SELECT * FROM [table] WHERE patient_id = '[unlinked-patient-uuid]';
```

### Phase 5: Generate Report

```markdown
# RLS Test Report: [table-name]

## Policies Tested
1. patients_select_own - SELECT for patients
2. patients_insert_own - INSERT for patients
3. therapists_select_linked - SELECT for therapists

## Test Results

| Test Case | Expected | Actual | Status |
|-----------|----------|--------|--------|
| Anon SELECT | Blocked | Blocked | PASS |
| Patient SELECT own | Allowed | Allowed | PASS |
| Patient SELECT other | Blocked | Blocked | PASS |
| Therapist SELECT linked | Allowed | Allowed | PASS |
| Therapist SELECT unlinked | Blocked | Blocked | PASS |

## Recommendations
- All policies functioning correctly
- Consider adding DELETE policy for patients
```

## Output

```
RLS Test Complete: patients

Policies: 4 found
Tests: 8 passed, 0 failed

Anonymous Access: BLOCKED
Patient Self-Access: ALLOWED
Cross-Patient Access: BLOCKED
Therapist Linked Access: ALLOWED

All RLS policies working correctly.
```

## Reference

- `supabase/migrations/` - RLS policy definitions
- Supabase Dashboard: Authentication > Policies
- `supabase/functions/ai-safety-check/` - Runtime safety validation
