# Security Guide for PT Performance

**Purpose:** Comprehensive security guide covering Row Level Security (RLS), authentication, authorization, and data protection.

**Context:** Build 45 security audit to ensure patient data is properly protected and access is correctly restricted by role.

---

## Table of Contents

1. [Quick Security Checklist](#quick-security-checklist)
2. [Row Level Security (RLS)](#row-level-security-rls)
3. [Authentication & Authorization](#authentication--authorization)
4. [Data Protection](#data-protection)
5. [API Security](#api-security)
6. [Testing Security](#testing-security)
7. [Security Incident Response](#security-incident-response)

---

## Quick Security Checklist

### Before Every Deployment

- [ ] Run RLS verification: `python3 scripts/verify_rls_policies.py`
- [ ] Run RLS policy tests: `xcodebuild test -only-testing:RLSPolicyTests`
- [ ] Verify no hardcoded credentials in code
- [ ] Check Sentry for authentication errors
- [ ] Review new RLS policies with team
- [ ] Test with both patient and therapist accounts

### Monthly Security Audit

- [ ] Review all RLS policies
- [ ] Check for data access violations in logs
- [ ] Update dependencies for security patches
- [ ] Review user access patterns
- [ ] Audit API key usage
- [ ] Check for PII leakage in logs

---

## Row Level Security (RLS)

### What is RLS?

Row Level Security (RLS) is a database feature that restricts which rows users can access based on policies.

**Without RLS:**
```sql
-- Patient can see ALL patients (BAD!)
SELECT * FROM patients;
```

**With RLS:**
```sql
-- Patient can ONLY see their own row (GOOD!)
SELECT * FROM patients; -- Returns only WHERE id = auth.uid()
```

---

### RLS Policy Structure

Every table should have RLS enabled and policies for each operation:

```sql
-- Enable RLS
ALTER TABLE patients ENABLE ROW LEVEL SECURITY;

-- SELECT policy (who can read)
CREATE POLICY "Patients can view own data"
    ON patients FOR SELECT
    USING (id = auth.uid());

CREATE POLICY "Therapists can view all patients"
    ON patients FOR SELECT
    USING (auth.role() = 'therapist');

-- INSERT policy (who can create)
CREATE POLICY "Therapists can create patients"
    ON patients FOR INSERT
    WITH CHECK (auth.role() = 'therapist');

-- UPDATE policy (who can modify)
CREATE POLICY "Therapists can update patients"
    ON patients FOR UPDATE
    USING (auth.role() = 'therapist')
    WITH CHECK (auth.role() = 'therapist');

-- DELETE policy (who can delete)
CREATE POLICY "Therapists can delete patients"
    ON patients FOR DELETE
    USING (auth.role() = 'therapist');
```

---

### Critical Tables and Their Policies

#### 1. Patients Table

**Security Requirements:**
- Patients can view their own data only
- Therapists can view all patients
- Only therapists can create/modify/delete patients

**Policies:**
```sql
-- SELECT
CREATE POLICY "Patients view own" ON patients FOR SELECT
    USING (id = auth.uid());

CREATE POLICY "Therapists view all" ON patients FOR SELECT
    USING (auth.role() = 'therapist');

-- INSERT/UPDATE/DELETE
CREATE POLICY "Therapists manage" ON patients FOR ALL
    USING (auth.role() = 'therapist');
```

---

#### 2. Programs Table

**Security Requirements:**
- Patients can view their own programs
- Therapists can view and manage all programs

**Policies:**
```sql
CREATE POLICY "Patients view own programs" ON programs FOR SELECT
    USING (patient_id = auth.uid());

CREATE POLICY "Therapists view all programs" ON programs FOR SELECT
    USING (auth.role() = 'therapist');

CREATE POLICY "Therapists manage programs" ON programs FOR ALL
    USING (auth.role() = 'therapist');
```

---

#### 3. Exercise Logs Table

**Security Requirements:**
- Patients can view and create their own logs
- Therapists can view and manage patient logs
- Patients cannot modify/delete logs (data integrity)

**Policies:**
```sql
CREATE POLICY "Patients view own logs" ON exercise_logs FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM exercises e
            JOIN sessions s ON e.session_id = s.id
            JOIN phases ph ON s.phase_id = ph.id
            JOIN programs p ON ph.program_id = p.id
            WHERE e.id = exercise_logs.exercise_id
            AND p.patient_id = auth.uid()
        )
    );

CREATE POLICY "Patients create own logs" ON exercise_logs FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM exercises e
            JOIN sessions s ON e.session_id = s.id
            JOIN phases ph ON s.phase_id = ph.id
            JOIN programs p ON ph.program_id = p.id
            WHERE e.id = exercise_logs.exercise_id
            AND p.patient_id = auth.uid()
        )
    );

CREATE POLICY "Therapists manage all logs" ON exercise_logs FOR ALL
    USING (auth.role() = 'therapist');
```

---

#### 4. Workload Flags Table

**Security Requirements:**
- Patients can view their own flags (read-only)
- Therapists can create and manage all flags

**Policies:**
```sql
CREATE POLICY "Patients view own flags" ON workload_flags FOR SELECT
    USING (patient_id = auth.uid());

CREATE POLICY "Therapists view all flags" ON workload_flags FOR SELECT
    USING (auth.role() = 'therapist');

CREATE POLICY "Therapists create flags" ON workload_flags FOR INSERT
    WITH CHECK (auth.role() = 'therapist');

CREATE POLICY "Therapists manage flags" ON workload_flags FOR UPDATE
    USING (auth.role() = 'therapist');
```

---

### Common RLS Mistakes

#### ❌ Mistake 1: RLS Disabled

```sql
-- BAD - RLS disabled, all data public!
ALTER TABLE patients DISABLE ROW LEVEL SECURITY;
```

**Fix:**
```sql
-- GOOD - RLS enabled
ALTER TABLE patients ENABLE ROW LEVEL SECURITY;
```

---

#### ❌ Mistake 2: No Policies

```sql
-- BAD - RLS enabled but no policies = nobody can access!
ALTER TABLE patients ENABLE ROW LEVEL SECURITY;
-- No policies created
```

**Fix:**
```sql
-- GOOD - Create policies after enabling RLS
ALTER TABLE patients ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow access" ON patients FOR SELECT
    USING (true); -- Or proper access control
```

---

#### ❌ Mistake 3: Overly Permissive Policy

```sql
-- BAD - Using 'true' grants access to ALL rows!
CREATE POLICY "Public access" ON patients FOR SELECT
    USING (true);
```

**Fix:**
```sql
-- GOOD - Proper access control
CREATE POLICY "Controlled access" ON patients FOR SELECT
    USING (id = auth.uid() OR auth.role() = 'therapist');
```

---

#### ❌ Mistake 4: Missing WITH CHECK on INSERT

```sql
-- BAD - Can insert any patient_id
CREATE POLICY "Insert logs" ON exercise_logs FOR INSERT
    USING (true); -- Only checks SELECT, not INSERT!
```

**Fix:**
```sql
-- GOOD - WITH CHECK validates INSERT data
CREATE POLICY "Insert own logs" ON exercise_logs FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM programs
            WHERE patient_id = auth.uid()
        )
    );
```

---

### Testing RLS Policies

#### 1. Automated Verification

```bash
# Run RLS verification script
python3 scripts/verify_rls_policies.py

# Run RLS integration tests
xcodebuild test \
  -project ios-app/PTPerformance.xcodeproj \
  -scheme PTPerformance \
  -only-testing:PTPerformanceTests/RLSPolicyTests
```

#### 2. Manual Testing

```bash
# Test as patient
psql "$SUPABASE_DB_URL" -c "
SET request.jwt.claim.sub = '<patient_uuid>';
SET request.jwt.claim.role = 'patient';

SELECT * FROM patients; -- Should see only own row
SELECT * FROM programs; -- Should see only own programs
"

# Test as therapist
psql "$SUPABASE_DB_URL" -c "
SET request.jwt.claim.sub = '<therapist_uuid>';
SET request.jwt.claim.role = 'therapist';

SELECT * FROM patients; -- Should see all patients
"
```

---

## Authentication & Authorization

### Authentication Flow

1. **User Login**
   ```swift
   let session = try await supabase.client.auth.signIn(
       email: email,
       password: password
   )
   ```

2. **Session Token**
   - JWT token stored securely in Keychain
   - Auto-refreshed before expiration
   - Included in all API requests

3. **User Context**
   ```swift
   // Set user context for error tracking
   ErrorLogger.shared.setUser(
       userId: session.user.id.uuidString,
       userType: userRole.rawValue
   )
   ```

---

### Authorization Levels

**Patient:**
- View own data (programs, sessions, exercises, logs)
- Create exercise logs for own programs
- View own workload flags (read-only)
- View own readiness data

**Therapist:**
- View all patients
- Create/modify/delete programs
- View all exercise logs
- Create workload flags
- View all readiness data

---

### Implementing Authorization in iOS

```swift
// Check user role before showing UI
if appState.userRole == .therapist {
    // Show therapist dashboard
    TherapistDashboardView()
} else {
    // Show patient dashboard
    PatientDashboardView()
}

// Don't rely on client-side auth alone!
// Always enforce with RLS policies on server
```

---

## Data Protection

### Sensitive Data Handling

**Never Log:**
- Passwords
- Email addresses (use user ID instead)
- Full names in error logs
- Authentication tokens
- Medical information

**Example:**
```swift
// ❌ BAD - Logs sensitive data
print("Login failed for \(email): \(password)")

// ✅ GOOD - Logs sanitized data
ErrorLogger.shared.log(
    error,
    context: [
        "user_id": userId,  // ID, not email
        "user_role": role   // Generic info
    ]
)
```

---

### PII (Personally Identifiable Information)

**What is PII:**
- Email addresses
- Full names
- Phone numbers
- Date of birth
- Medical information
- Location data

**Protection:**
```swift
// Don't send PII to analytics
ErrorLogger.shared.logUserAction(
    action: "workout_completed",
    properties: [
        "user_id": userId,  // ✅ OK (anonymized)
        // "name": fullName  // ❌ Don't include PII
    ]
)

// Filter PII from Sentry
SentrySDK.start { options in
    options.beforeSend = { event in
        // Remove any PII from event
        return event
    }
}
```

---

### Data Encryption

**In Transit:**
- All API calls use HTTPS
- TLS 1.2+ required
- Certificate pinning (optional, advanced)

**At Rest:**
- Database encryption (Supabase handles this)
- Local data encrypted in Keychain
- Temporary files encrypted

---

## API Security

### API Key Management

**Never:**
- Hardcode API keys in code
- Commit API keys to git
- Share API keys in Slack/email
- Use production keys in development

**Instead:**
```swift
// Load from environment or config
let apiKey = ProcessInfo.processInfo.environment["SUPABASE_KEY"]
    ?? Config.supabaseAnonKey
```

---

### Rate Limiting

Supabase has built-in rate limiting:
- 100 requests/second per IP (authenticated)
- 10 requests/second per IP (unauthenticated)

**Client-side handling:**
```swift
do {
    let result = try await supabase.client
        .from("patients")
        .select()
        .execute()
        .value
} catch {
    if error.localizedDescription.contains("rate limit") {
        // Wait and retry
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1s
        // Retry operation
    }
}
```

---

## Testing Security

### Security Test Checklist

**Authentication Tests:**
- [ ] Users cannot access data without login
- [ ] Expired tokens are rejected
- [ ] Invalid credentials are rejected
- [ ] Password reset flow works securely

**Authorization Tests:**
- [ ] Patients can only see own data
- [ ] Therapists can see all patient data
- [ ] Patients cannot delete programs
- [ ] Cross-patient access is blocked

**RLS Tests:**
- [ ] All tables have RLS enabled
- [ ] All tables have appropriate policies
- [ ] Unauthenticated access is blocked
- [ ] No overly permissive policies

**Data Protection Tests:**
- [ ] No PII in error logs
- [ ] No passwords in logs
- [ ] API keys not exposed
- [ ] Sensitive data encrypted

---

### Running Security Tests

```bash
# RLS verification
python3 scripts/verify_rls_policies.py

# RLS policy tests
xcodebuild test -only-testing:PTPerformanceTests/RLSPolicyTests

# Check for secrets in code
git secrets --scan

# Dependency vulnerability check
npm audit  # or equivalent for Swift packages
```

---

## Security Incident Response

### If Data Breach Suspected

1. **Immediate Actions**
   - Lock down affected accounts
   - Disable API keys
   - Check Sentry for suspicious activity
   - Review database access logs

2. **Investigation**
   - Identify scope of breach
   - Check RLS policies for violations
   - Review recent code changes
   - Check for unauthorized database access

3. **Remediation**
   - Fix security vulnerability
   - Reset affected credentials
   - Notify affected users (if legally required)
   - Update security policies

4. **Post-Incident**
   - Document incident in Linear
   - Update security procedures
   - Conduct security audit
   - Train team on prevention

---

### Emergency Contacts

**Security Issues:**
- Create Linear issue with label `security` and priority `critical`
- Alert in #pt-performance-alerts
- Escalate to CTO if data breach suspected

---

## Related Documentation

- [RLS Policy Verification](../scripts/verify_rls_policies.py)
- [Integration Testing Guide](./INTEGRATION_TESTING.md)
- [Error Handling Best Practices](./ERROR_HANDLING.md)

---

## Security Resources

**Supabase Security:**
- https://supabase.com/docs/guides/auth/row-level-security
- https://supabase.com/docs/guides/auth/managing-user-data

**OWASP Guidelines:**
- https://owasp.org/www-project-mobile-top-10/
- https://owasp.org/www-project-api-security/

---

**Last Updated:** 2025-12-15 (Build 45)
**Owner:** Build 45 Swarm Agent 4 (Security Engineer)
