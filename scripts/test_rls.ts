/**
 * RLS Policy Test Suite
 *
 * Tests Row Level Security policies using the Supabase client
 * to verify patients can only access their own data.
 *
 * Usage:
 *   npx ts-node scripts/test_rls.ts
 *   # or
 *   SUPABASE_URL=xxx SUPABASE_ANON_KEY=xxx npx ts-node scripts/test_rls.ts
 *
 * Prerequisites:
 *   - npm install @supabase/supabase-js
 *   - Test users must exist in the database
 */

import { createClient, SupabaseClient, User } from '@supabase/supabase-js';

// ============================================================================
// CONFIGURATION
// ============================================================================

const SUPABASE_URL = process.env.SUPABASE_URL || 'https://rpbxeaxlaoyoqkohytlw.supabase.co';
const SUPABASE_ANON_KEY = process.env.SUPABASE_ANON_KEY || 'sb_publishable_bvF02gZep-IdSHFNYVro3g_lNY8hfzr';

// Test user credentials - update these with real test users
const TEST_USERS = {
    patientA: {
        email: process.env.TEST_PATIENT_A_EMAIL || 'demo-patient@ptperformance.app',
        password: process.env.TEST_PATIENT_A_PASSWORD || 'demo-patient-2025',
    },
    patientB: {
        email: process.env.TEST_PATIENT_B_EMAIL || 'nic.brebbia@gmail.com',
        password: process.env.TEST_PATIENT_B_PASSWORD || 'demo-patient-2025',
    },
    therapist: {
        email: process.env.TEST_THERAPIST_EMAIL || 'demo-pt@ptperformance.app',
        password: process.env.TEST_THERAPIST_PASSWORD || 'demo-therapist-2025',
    },
};

// ============================================================================
// TYPES
// ============================================================================

interface TestResult {
    name: string;
    table: string;
    operation: string;
    passed: boolean;
    expected: string;
    actual: string;
    error?: string;
}

interface TestContext {
    client: SupabaseClient;
    user: User | null;
    patientId: string | null;
}

// ============================================================================
// TEST UTILITIES
// ============================================================================

class RLSTestSuite {
    private results: TestResult[] = [];
    private patientAContext: TestContext | null = null;
    private patientBContext: TestContext | null = null;
    private therapistContext: TestContext | null = null;

    /**
     * Create authenticated Supabase client for a user
     */
    async createAuthenticatedClient(email: string, password: string): Promise<TestContext> {
        const client = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

        const { data, error } = await client.auth.signInWithPassword({
            email,
            password,
        });

        if (error) {
            throw new Error(`Failed to authenticate ${email}: ${error.message}`);
        }

        // Get the patient_id for this user
        let patientId: string | null = null;
        const { data: patients } = await client
            .from('patients')
            .select('id')
            .limit(1);

        if (patients && patients.length > 0) {
            patientId = patients[0].id;
        }

        return {
            client,
            user: data.user,
            patientId,
        };
    }

    /**
     * Log a test result
     */
    private logResult(result: TestResult): void {
        this.results.push(result);
        const status = result.passed ? '\x1b[32mPASS\x1b[0m' : '\x1b[31mFAIL\x1b[0m';
        console.log(`  [${status}] ${result.name}`);
        if (!result.passed) {
            console.log(`    Expected: ${result.expected}`);
            console.log(`    Actual: ${result.actual}`);
            if (result.error) {
                console.log(`    Error: ${result.error}`);
            }
        }
    }

    // ========================================================================
    // SETUP
    // ========================================================================

    async setup(): Promise<boolean> {
        console.log('\n============================================');
        console.log('RLS POLICY TEST SUITE');
        console.log('============================================\n');

        console.log('Setting up test contexts...\n');

        try {
            // Authenticate Patient A
            console.log(`Authenticating Patient A (${TEST_USERS.patientA.email})...`);
            this.patientAContext = await this.createAuthenticatedClient(
                TEST_USERS.patientA.email,
                TEST_USERS.patientA.password
            );
            console.log(`  User ID: ${this.patientAContext.user?.id}`);
            console.log(`  Patient ID: ${this.patientAContext.patientId || 'Not found'}\n`);

            // Authenticate Patient B
            console.log(`Authenticating Patient B (${TEST_USERS.patientB.email})...`);
            this.patientBContext = await this.createAuthenticatedClient(
                TEST_USERS.patientB.email,
                TEST_USERS.patientB.password
            );
            console.log(`  User ID: ${this.patientBContext.user?.id}`);
            console.log(`  Patient ID: ${this.patientBContext.patientId || 'Not found'}\n`);

            // Authenticate Therapist
            console.log(`Authenticating Therapist (${TEST_USERS.therapist.email})...`);
            this.therapistContext = await this.createAuthenticatedClient(
                TEST_USERS.therapist.email,
                TEST_USERS.therapist.password
            );
            console.log(`  User ID: ${this.therapistContext.user?.id}\n`);

            return true;
        } catch (error) {
            console.error('Setup failed:', error);
            return false;
        }
    }

    // ========================================================================
    // LAB RESULTS TESTS
    // ========================================================================

    async testLabResults(): Promise<void> {
        console.log('\n--- Testing lab_results RLS ---\n');

        if (!this.patientAContext || !this.patientBContext) {
            console.log('  SKIP: Patient contexts not available');
            return;
        }

        const patientAId = this.patientAContext.user?.id;
        const patientBId = this.patientBContext.user?.id;

        // Test: Patient A can read own lab results
        const { data: ownData, error: ownError } = await this.patientAContext.client
            .from('lab_results')
            .select('*')
            .eq('patient_id', patientAId);

        this.logResult({
            name: 'Patient A can SELECT own lab_results',
            table: 'lab_results',
            operation: 'SELECT',
            passed: !ownError,
            expected: 'Query succeeds',
            actual: ownError ? `Error: ${ownError.message}` : `Found ${ownData?.length || 0} records`,
            error: ownError?.message,
        });

        // Test: Patient A cannot read Patient B's lab results
        const { data: otherData, error: otherError } = await this.patientAContext.client
            .from('lab_results')
            .select('*')
            .eq('patient_id', patientBId);

        this.logResult({
            name: 'Patient A cannot SELECT Patient B lab_results',
            table: 'lab_results',
            operation: 'SELECT',
            passed: !otherData || otherData.length === 0,
            expected: '0 records returned',
            actual: `${otherData?.length || 0} records returned`,
        });
    }

    // ========================================================================
    // FASTING LOGS TESTS
    // ========================================================================

    async testFastingLogs(): Promise<void> {
        console.log('\n--- Testing fasting_logs RLS ---\n');

        if (!this.patientAContext || !this.patientBContext) {
            console.log('  SKIP: Patient contexts not available');
            return;
        }

        const patientAId = this.patientAContext.user?.id;
        const patientBId = this.patientBContext.user?.id;

        // Test: Patient A can read own fasting logs
        const { data: ownData, error: ownError } = await this.patientAContext.client
            .from('fasting_logs')
            .select('*')
            .eq('patient_id', patientAId);

        this.logResult({
            name: 'Patient A can SELECT own fasting_logs',
            table: 'fasting_logs',
            operation: 'SELECT',
            passed: !ownError,
            expected: 'Query succeeds',
            actual: ownError ? `Error: ${ownError.message}` : `Found ${ownData?.length || 0} records`,
        });

        // Test: Patient A cannot insert fasting log for Patient B
        const { error: insertError } = await this.patientAContext.client
            .from('fasting_logs')
            .insert({
                patient_id: patientBId,
                started_at: new Date().toISOString(),
                planned_hours: 16,
            });

        this.logResult({
            name: 'Patient A cannot INSERT fasting_logs for Patient B',
            table: 'fasting_logs',
            operation: 'INSERT',
            passed: !!insertError,
            expected: 'Insert blocked by RLS',
            actual: insertError ? 'Insert blocked' : 'Insert succeeded - RLS GAP!',
            error: insertError?.message,
        });
    }

    // ========================================================================
    // SUPPLEMENT LOGS TESTS
    // ========================================================================

    async testSupplementLogs(): Promise<void> {
        console.log('\n--- Testing supplement_logs RLS ---\n');

        if (!this.patientAContext || !this.patientBContext) {
            console.log('  SKIP: Patient contexts not available');
            return;
        }

        const patientBId = this.patientBContext.user?.id;

        // Test: Patient A cannot read Patient B's supplement logs
        const { data: otherData } = await this.patientAContext.client
            .from('supplement_logs')
            .select('*')
            .eq('patient_id', patientBId);

        this.logResult({
            name: 'Patient A cannot SELECT Patient B supplement_logs',
            table: 'supplement_logs',
            operation: 'SELECT',
            passed: !otherData || otherData.length === 0,
            expected: '0 records returned',
            actual: `${otherData?.length || 0} records returned`,
        });
    }

    // ========================================================================
    // PATIENT SUPPLEMENT STACKS TESTS
    // ========================================================================

    async testPatientSupplementStacks(): Promise<void> {
        console.log('\n--- Testing patient_supplement_stacks RLS ---\n');

        if (!this.patientAContext || !this.patientBContext) {
            console.log('  SKIP: Patient contexts not available');
            return;
        }

        const patientAId = this.patientAContext.user?.id;
        const patientBId = this.patientBContext.user?.id;

        // Test: Patient A can read own stacks
        const { data: ownData, error: ownError } = await this.patientAContext.client
            .from('patient_supplement_stacks')
            .select('*')
            .eq('patient_id', patientAId);

        this.logResult({
            name: 'Patient A can SELECT own supplement_stacks',
            table: 'patient_supplement_stacks',
            operation: 'SELECT',
            passed: !ownError,
            expected: 'Query succeeds',
            actual: ownError ? `Error: ${ownError.message}` : `Found ${ownData?.length || 0} records`,
        });

        // Test: Patient A cannot update Patient B's stacks
        const { error: updateError, count } = await this.patientAContext.client
            .from('patient_supplement_stacks')
            .update({ notes: 'Malicious update' })
            .eq('patient_id', patientBId);

        this.logResult({
            name: 'Patient A cannot UPDATE Patient B supplement_stacks',
            table: 'patient_supplement_stacks',
            operation: 'UPDATE',
            passed: count === 0 || !!updateError,
            expected: '0 rows updated or blocked',
            actual: updateError ? 'Update blocked' : `${count || 0} rows updated`,
        });
    }

    // ========================================================================
    // RECOVERY SESSIONS TESTS
    // ========================================================================

    async testRecoverySessions(): Promise<void> {
        console.log('\n--- Testing recovery_sessions RLS ---\n');

        if (!this.patientAContext || !this.patientBContext) {
            console.log('  SKIP: Patient contexts not available');
            return;
        }

        const patientBId = this.patientBContext.user?.id;

        // Test: Patient A cannot delete Patient B's recovery sessions
        const { error: deleteError, count } = await this.patientAContext.client
            .from('recovery_sessions')
            .delete()
            .eq('patient_id', patientBId);

        this.logResult({
            name: 'Patient A cannot DELETE Patient B recovery_sessions',
            table: 'recovery_sessions',
            operation: 'DELETE',
            passed: count === 0 || !!deleteError,
            expected: '0 rows deleted or blocked',
            actual: deleteError ? 'Delete blocked' : `${count || 0} rows deleted`,
        });
    }

    // ========================================================================
    // AI COACH TESTS
    // ========================================================================

    async testAICoachConversations(): Promise<void> {
        console.log('\n--- Testing ai_coach_conversations RLS ---\n');

        if (!this.patientAContext || !this.patientBContext) {
            console.log('  SKIP: Patient contexts not available');
            return;
        }

        const patientBId = this.patientBContext.user?.id;

        // Test: Patient A cannot read Patient B's conversations
        const { data: otherData } = await this.patientAContext.client
            .from('ai_coach_conversations')
            .select('*')
            .eq('patient_id', patientBId);

        this.logResult({
            name: 'Patient A cannot SELECT Patient B ai_coach_conversations',
            table: 'ai_coach_conversations',
            operation: 'SELECT',
            passed: !otherData || otherData.length === 0,
            expected: '0 records returned',
            actual: `${otherData?.length || 0} records returned`,
        });
    }

    // ========================================================================
    // DAILY READINESS TESTS
    // ========================================================================

    async testDailyReadiness(): Promise<void> {
        console.log('\n--- Testing daily_readiness RLS ---\n');

        if (!this.patientAContext || !this.patientBContext) {
            console.log('  SKIP: Patient contexts not available');
            return;
        }

        const patientAId = this.patientAContext.user?.id;
        const patientBId = this.patientBContext.user?.id;

        // Test: Patient A can read own readiness
        const { data: ownData, error: ownError } = await this.patientAContext.client
            .from('daily_readiness')
            .select('*')
            .eq('patient_id', patientAId);

        this.logResult({
            name: 'Patient A can SELECT own daily_readiness',
            table: 'daily_readiness',
            operation: 'SELECT',
            passed: !ownError,
            expected: 'Query succeeds',
            actual: ownError ? `Error: ${ownError.message}` : `Found ${ownData?.length || 0} records`,
        });

        // Test: Patient A cannot read Patient B's readiness
        const { data: otherData } = await this.patientAContext.client
            .from('daily_readiness')
            .select('*')
            .eq('patient_id', patientBId);

        this.logResult({
            name: 'Patient A cannot SELECT Patient B daily_readiness',
            table: 'daily_readiness',
            operation: 'SELECT',
            passed: !otherData || otherData.length === 0,
            expected: '0 records returned',
            actual: `${otherData?.length || 0} records returned`,
        });
    }

    // ========================================================================
    // THERAPIST ACCESS TESTS
    // ========================================================================

    async testTherapistLinkedPatientAccess(): Promise<void> {
        console.log('\n--- Testing Therapist Access to Linked Patients ---\n');

        if (!this.therapistContext || !this.patientAContext) {
            console.log('  SKIP: Therapist or patient context not available');
            return;
        }

        const patientAId = this.patientAContext.user?.id;

        // Check if therapist is linked to patient A
        const { data: linkage } = await this.therapistContext.client
            .from('therapist_patients')
            .select('*')
            .eq('patient_id', patientAId)
            .eq('therapist_id', this.therapistContext.user?.id)
            .eq('active', true);

        const isLinked = linkage && linkage.length > 0;
        console.log(`  Therapist linked to Patient A: ${isLinked}`);

        // Test: Therapist can view linked patient's lab results
        const { data: labData, error: labError } = await this.therapistContext.client
            .from('lab_results')
            .select('*')
            .eq('patient_id', patientAId);

        this.logResult({
            name: 'Therapist can SELECT linked patient lab_results',
            table: 'lab_results',
            operation: 'SELECT',
            passed: isLinked ? !labError : (labData?.length === 0 || !!labError),
            expected: isLinked ? 'Query succeeds' : 'Query blocked',
            actual: labError ? `Error: ${labError.message}` : `Found ${labData?.length || 0} records`,
        });

        // Test: Therapist can view linked patient's recovery sessions
        const { data: recoveryData, error: recoveryError } = await this.therapistContext.client
            .from('recovery_sessions')
            .select('*')
            .eq('patient_id', patientAId);

        this.logResult({
            name: 'Therapist can SELECT linked patient recovery_sessions',
            table: 'recovery_sessions',
            operation: 'SELECT',
            passed: isLinked ? !recoveryError : (recoveryData?.length === 0 || !!recoveryError),
            expected: isLinked ? 'Query succeeds' : 'Query blocked',
            actual: recoveryError ? `Error: ${recoveryError.message}` : `Found ${recoveryData?.length || 0} records`,
        });
    }

    async testTherapistUnlinkedPatientAccess(): Promise<void> {
        console.log('\n--- Testing Therapist Cannot Access Unlinked Patients ---\n');

        if (!this.therapistContext || !this.patientBContext) {
            console.log('  SKIP: Therapist or patient context not available');
            return;
        }

        const patientBId = this.patientBContext.user?.id;
        const therapistId = this.therapistContext.user?.id;

        // Check if therapist is NOT linked to patient B
        const { data: linkage } = await this.therapistContext.client
            .from('therapist_patients')
            .select('*')
            .eq('patient_id', patientBId)
            .eq('therapist_id', therapistId)
            .eq('active', true);

        const isLinked = linkage && linkage.length > 0;

        if (isLinked) {
            console.log('  SKIP: Therapist IS linked to Patient B, cannot test unlinked access');
            return;
        }

        // Test: Therapist cannot view unlinked patient's lab results
        const { data: labData } = await this.therapistContext.client
            .from('lab_results')
            .select('*')
            .eq('patient_id', patientBId);

        this.logResult({
            name: 'Therapist cannot SELECT unlinked patient lab_results',
            table: 'lab_results',
            operation: 'SELECT',
            passed: !labData || labData.length === 0,
            expected: '0 records returned',
            actual: `${labData?.length || 0} records returned`,
        });

        // Test: Therapist cannot view unlinked patient's daily readiness
        const { data: readinessData } = await this.therapistContext.client
            .from('daily_readiness')
            .select('*')
            .eq('patient_id', patientBId);

        this.logResult({
            name: 'Therapist cannot SELECT unlinked patient daily_readiness',
            table: 'daily_readiness',
            operation: 'SELECT',
            passed: !readinessData || readinessData.length === 0,
            expected: '0 records returned',
            actual: `${readinessData?.length || 0} records returned`,
        });
    }

    // ========================================================================
    // RUN ALL TESTS
    // ========================================================================

    async runAllTests(): Promise<void> {
        const setupSuccess = await this.setup();
        if (!setupSuccess) {
            console.log('\nTest setup failed. Aborting tests.\n');
            process.exit(1);
        }

        // Run all test suites
        await this.testLabResults();
        await this.testFastingLogs();
        await this.testSupplementLogs();
        await this.testPatientSupplementStacks();
        await this.testRecoverySessions();
        await this.testAICoachConversations();
        await this.testDailyReadiness();
        await this.testTherapistLinkedPatientAccess();
        await this.testTherapistUnlinkedPatientAccess();

        // Print summary
        this.printSummary();
    }

    // ========================================================================
    // SUMMARY
    // ========================================================================

    printSummary(): void {
        console.log('\n============================================');
        console.log('TEST SUMMARY');
        console.log('============================================\n');

        const passed = this.results.filter((r) => r.passed).length;
        const failed = this.results.filter((r) => !r.passed).length;
        const total = this.results.length;

        console.log(`Total Tests: ${total}`);
        console.log(`\x1b[32mPassed: ${passed}\x1b[0m`);
        console.log(`\x1b[31mFailed: ${failed}\x1b[0m`);

        if (failed > 0) {
            console.log('\n--- FAILED TESTS (RLS GAPS DETECTED) ---\n');
            for (const result of this.results.filter((r) => !r.passed)) {
                console.log(`  [FAIL] ${result.name}`);
                console.log(`    Table: ${result.table}`);
                console.log(`    Operation: ${result.operation}`);
                console.log(`    Expected: ${result.expected}`);
                console.log(`    Actual: ${result.actual}`);
                if (result.error) {
                    console.log(`    Error: ${result.error}`);
                }
                console.log();
            }
        }

        console.log('\n============================================');

        // Exit with error code if any tests failed
        if (failed > 0) {
            console.log('\nRLS POLICY GAPS DETECTED! Please review and fix.\n');
            process.exit(1);
        } else {
            console.log('\nAll RLS policies are working correctly!\n');
            process.exit(0);
        }
    }

    // ========================================================================
    // CLEANUP
    // ========================================================================

    async cleanup(): Promise<void> {
        console.log('\nCleaning up...');

        if (this.patientAContext) {
            await this.patientAContext.client.auth.signOut();
        }
        if (this.patientBContext) {
            await this.patientBContext.client.auth.signOut();
        }
        if (this.therapistContext) {
            await this.therapistContext.client.auth.signOut();
        }

        console.log('Cleanup complete.\n');
    }
}

// ============================================================================
// MAIN
// ============================================================================

async function main(): Promise<void> {
    const testSuite = new RLSTestSuite();

    try {
        await testSuite.runAllTests();
    } catch (error) {
        console.error('Test suite error:', error);
        process.exit(1);
    } finally {
        await testSuite.cleanup();
    }
}

main();
