# RLS Policy Audit Report

## Overview

This document provides a comprehensive audit of Row Level Security (RLS) policies
for the PT Performance database, identifying gaps and providing fixes.

**Audit Date**: 2026-02-03

## Tables Audited

| Table | RLS Enabled | Patient Policy | Therapist Policy | Status |
|-------|-------------|----------------|------------------|--------|
| lab_results | Yes | patient_id = auth.uid() | therapist_patients linkage | OK |
| biomarker_values | Yes | via lab_results join | via lab_results join | OK |
| recovery_sessions | Yes | patient_id = auth.uid() | therapist_patients linkage | OK |
| fasting_logs | Yes | patient_id = auth.uid() | therapist_patients linkage | OK |
| supplement_logs | Yes | patient_id = auth.uid() | therapist_patients linkage | OK |
| patient_supplement_stacks | Yes | patient_id = auth.uid() | therapist_patients linkage | OK |
| ai_coach_conversations | Yes | patient_id = auth.uid() | N/A | OK |
| ai_coach_messages | Yes | via conversation join | N/A | OK |
| daily_readiness | Yes | patient_id = auth.uid() | Varies* | REVIEW |

## Identified Gaps

### 1. Daily Readiness - Inconsistent Therapist Policy

**Issue**: The `daily_readiness` table has multiple migrations that may have
conflicting RLS policies. Some policies check `therapist_patients` linkage,
while others grant broad access to anyone with the `therapist` role.

**Risk Level**: Medium

**Current State**:
- Patient policies: Correctly use `patient_id = auth.uid()`
- Therapist policies: May not consistently check linkage

**Fix**:
```sql
-- Drop existing therapist policies
DROP POLICY IF EXISTS "Therapists can view all readiness data" ON daily_readiness;
DROP POLICY IF EXISTS "Therapists can view assigned patients readiness" ON daily_readiness;

-- Create proper therapist policy with linkage check
CREATE POLICY "Therapists view linked patient readiness"
    ON daily_readiness FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM therapist_patients tp
            WHERE tp.patient_id = daily_readiness.patient_id
            AND tp.therapist_id = auth.uid()
            AND tp.active = true
        )
    );
```

### 2. AI Coach - Missing Therapist Access

**Issue**: Therapists cannot view their patients' AI coach conversations,
which may be needed for care coordination.

**Risk Level**: Low (feature gap, not security)

**Current State**:
- Only patients can access their own conversations
- Therapists have no access even to linked patients

**Recommendation**: Consider adding therapist read access if clinically appropriate:
```sql
CREATE POLICY "Therapists view linked patient ai_coach_conversations"
    ON ai_coach_conversations FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM therapist_patients tp
            WHERE tp.patient_id = ai_coach_conversations.patient_id
            AND tp.therapist_id = auth.uid()
            AND tp.active = true
        )
    );

CREATE POLICY "Therapists view linked patient ai_coach_messages"
    ON ai_coach_messages FOR SELECT
    TO authenticated
    USING (
        conversation_id IN (
            SELECT c.id FROM ai_coach_conversations c
            JOIN therapist_patients tp ON tp.patient_id = c.patient_id
            WHERE tp.therapist_id = auth.uid()
            AND tp.active = true
        )
    );
```

### 3. Scheduled Sessions - Potential Broad Access

**Issue**: The `scheduled_sessions` table has a policy using `auth.role() = 'therapist'`
which is not a standard Supabase function and may not work as expected.

**Risk Level**: Medium

**Current State**:
```sql
-- This policy may not work as expected
USING (
    auth.role() = 'therapist' OR
    EXISTS (
        SELECT 1 FROM patients
        WHERE patients.id = scheduled_sessions.patient_id
        AND patients.therapist_id = auth.uid()
    )
);
```

**Fix**:
```sql
DROP POLICY IF EXISTS "Therapists view all scheduled sessions" ON scheduled_sessions;
DROP POLICY IF EXISTS "Therapists manage scheduled sessions" ON scheduled_sessions;

-- Use proper role check via user_roles table or therapist_patients
CREATE POLICY "Therapists view linked patient scheduled sessions"
    ON scheduled_sessions FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM therapist_patients tp
            WHERE tp.patient_id = scheduled_sessions.patient_id
            AND tp.therapist_id = auth.uid()
            AND tp.active = true
        )
    );
```

### 4. Missing DELETE Policy Verification

**Issue**: Some tables may have gaps in DELETE policies, allowing patients to
potentially delete data they shouldn't be able to.

**Tables to Verify**:
- biomarker_values (should only delete via lab_results ownership)
- ai_coach_messages (should not be deletable by users)

**Recommendation**: Audit all DELETE policies and ensure they are as restrictive as needed.

## Test Execution

### Using psql
```bash
psql $DATABASE_URL -f scripts/test_rls_policies.sql
```

### Using Supabase CLI
```bash
supabase test db
```

### Using TypeScript Tests
```bash
cd agent-service
npx ts-node ../scripts/test_rls.ts
```

## Test Scenarios Covered

### Patient Isolation Tests
- [x] User can read own lab_results
- [x] User cannot read other user's lab_results
- [x] User can insert own fasting_logs
- [x] User cannot insert fasting_logs for other users
- [x] User can update own supplement_stacks
- [x] User cannot delete other user's recovery_sessions

### Therapist Access Tests
- [x] Therapist can view linked patient data
- [x] Therapist cannot view unlinked patient data
- [ ] Therapist can insert data for linked patients (if applicable)
- [ ] Therapist cannot modify unlinked patient data

### Edge Cases
- [ ] Service role bypass works correctly
- [ ] Anonymous users have no access
- [ ] Deactivated therapist-patient links block access

## Recommendations

1. **Standardize Therapist Access Pattern**: All therapist access should use the
   `therapist_patients` table for linkage verification.

2. **Add Audit Logging**: Consider adding RLS-aware audit logging to track who
   accesses patient data.

3. **Regular Testing**: Run RLS tests as part of CI/CD pipeline.

4. **Documentation**: Keep RLS policies documented in migration comments.

5. **Security Review**: Conduct periodic security reviews of RLS policies,
   especially after adding new tables.

## Migration to Fix Gaps

Create a new migration file to address identified gaps:

```sql
-- Migration: 20260203_fix_rls_policy_gaps.sql

-- Fix daily_readiness therapist policy
DROP POLICY IF EXISTS "Therapists can view all readiness data" ON daily_readiness;

CREATE POLICY "Therapists view linked patient readiness"
    ON daily_readiness FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM therapist_patients tp
            WHERE tp.patient_id = daily_readiness.patient_id
            AND tp.therapist_id = auth.uid()
            AND tp.active = true
        )
    );

-- Add any other fixes here...
```

## Conclusion

The RLS policies are generally well-implemented with proper patient isolation.
The main areas for improvement are:

1. Ensuring consistent therapist access patterns across all tables
2. Adding therapist access to AI coach data if needed
3. Verifying DELETE policies are appropriately restrictive

Run the test scripts regularly to ensure RLS policies continue to work correctly
as the schema evolves.
