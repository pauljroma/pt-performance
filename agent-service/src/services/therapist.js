import { createClient } from '@supabase/supabase-js';
import { config } from '../config.js';

const supabase = createClient(config.supabase.url, config.supabase.serviceKey);

/**
 * Search patients with filters
 */
async function searchPatients(filters) {
    let query = supabase
        .from('patients')
        .select(`
            id,
            therapist_id,
            first_name,
            last_name,
            email,
            sport,
            position,
            injury_type,
            target_level,
            created_at,
            patient_flags(
                id,
                severity
            )
        `)
        .eq('therapist_id', filters.therapistId);

    // Text search
    if (filters.search) {
        query = query.or(
            `first_name.ilike.%${filters.search}%,last_name.ilike.%${filters.search}%,email.ilike.%${filters.search}%`
        );
    }

    // Sport filter
    if (filters.sport) {
        query = query.eq('sport', filters.sport);
    }

    // Position filter
    if (filters.position) {
        query = query.eq('position', filters.position);
    }

    const { data: patients, error } = await query;

    if (error) {
        throw new Error(`Failed to fetch patients: ${error.message}`);
    }

    // Enrich with flag counts and adherence
    const enrichedPatients = await Promise.all(
        patients.map(async (patient) => {
            // Count flags by severity
            const flags = patient.patient_flags || [];
            const highSeverityFlags = flags.filter(f => f.severity === 'HIGH').length;
            const mediumSeverityFlags = flags.filter(f => f.severity === 'MEDIUM').length;
            const lowSeverityFlags = flags.filter(f => f.severity === 'LOW').length;
            const totalFlags = flags.length;

            // Get adherence from view
            const { data: adherenceData } = await supabase
                .from('vw_patient_adherence')
                .select('adherence_pct, completed_sessions, total_sessions')
                .eq('patient_id', patient.id)
                .single();

            const adherencePercentage = adherenceData?.adherence_pct || 0;

            // Get last session date
            const { data: lastSession } = await supabase
                .from('sessions')
                .select('session_date')
                .eq('patient_id', patient.id)
                .order('session_date', { ascending: false })
                .limit(1)
                .single();

            return {
                id: patient.id,
                therapist_id: patient.therapist_id,
                first_name: patient.first_name,
                last_name: patient.last_name,
                email: patient.email,
                sport: patient.sport,
                position: patient.position,
                injury_type: patient.injury_type,
                target_level: patient.target_level,
                created_at: patient.created_at,
                flag_count: totalFlags,
                high_severity_flag_count: highSeverityFlags,
                medium_severity_flag_count: mediumSeverityFlags,
                low_severity_flag_count: lowSeverityFlags,
                adherence_percentage: adherencePercentage,
                completed_sessions: adherenceData?.completed_sessions || 0,
                total_sessions: adherenceData?.total_sessions || 0,
                last_session_date: lastSession?.session_date || null
            };
        })
    );

    // Apply post-query filters
    let filteredPatients = enrichedPatients;

    // Flag severity filter
    if (filters.flagSeverity) {
        const severityKey = `${filters.flagSeverity.toLowerCase()}_severity_flag_count`;
        filteredPatients = filteredPatients.filter(p => p[severityKey] > 0);
    }

    // Has flags filter
    if (filters.hasFlags !== null) {
        filteredPatients = filteredPatients.filter(p =>
            filters.hasFlags ? p.flag_count > 0 : p.flag_count === 0
        );
    }

    // Adherence range filter
    if (filters.minAdherence !== null) {
        filteredPatients = filteredPatients.filter(p =>
            p.adherence_percentage >= filters.minAdherence
        );
    }

    if (filters.maxAdherence !== null) {
        filteredPatients = filteredPatients.filter(p =>
            p.adherence_percentage <= filters.maxAdherence
        );
    }

    // Sort by high severity flags first, then by name
    filteredPatients.sort((a, b) => {
        if (b.high_severity_flag_count !== a.high_severity_flag_count) {
            return b.high_severity_flag_count - a.high_severity_flag_count;
        }
        return a.last_name.localeCompare(b.last_name);
    });

    return filteredPatients;
}

/**
 * Get dashboard summary for therapist
 */
async function getDashboardSummary(therapistId) {
    // Get all patients
    const { data: patients, error: patientsError } = await supabase
        .from('patients')
        .select('id')
        .eq('therapist_id', therapistId);

    if (patientsError) {
        throw new Error(`Failed to fetch patients: ${patientsError.message}`);
    }

    const patientIds = patients.map(p => p.id);

    // Get high severity flags
    const { data: highSeverityFlags, error: flagsError } = await supabase
        .from('patient_flags')
        .select('id, patient_id, flag_type, description')
        .in('patient_id', patientIds)
        .eq('severity', 'HIGH')
        .is('resolved_at', null);

    if (flagsError) {
        throw new Error(`Failed to fetch flags: ${flagsError.message}`);
    }

    // Get adherence summary
    const adherencePromises = patientIds.map(async (patientId) => {
        const { data } = await supabase
            .from('vw_patient_adherence')
            .select('adherence_pct')
            .eq('patient_id', patientId)
            .single();

        return data?.adherence_pct || 0;
    });

    const adherenceValues = await Promise.all(adherencePromises);
    const avgAdherence = adherenceValues.length > 0
        ? adherenceValues.reduce((sum, val) => sum + val, 0) / adherenceValues.length
        : 0;

    // Get sessions this week
    const weekStart = new Date();
    weekStart.setDate(weekStart.getDate() - weekStart.getDay());
    weekStart.setHours(0, 0, 0, 0);

    const { data: sessionData, error: sessionsError } = await supabase
        .from('sessions')
        .select('id, completed')
        .in('patient_id', patientIds)
        .gte('session_date', weekStart.toISOString());

    if (sessionsError) {
        throw new Error(`Failed to fetch sessions: ${sessionsError.message}`);
    }

    const completedThisWeek = sessionData?.filter(s => s.completed).length || 0;
    const totalThisWeek = sessionData?.length || 0;

    return {
        total_patients: patients.length,
        high_severity_flags: highSeverityFlags?.length || 0,
        avg_adherence: Math.round(avgAdherence * 10) / 10,
        sessions_this_week: {
            completed: completedThisWeek,
            total: totalThisWeek
        },
        patients_at_risk: highSeverityFlags?.length || 0
    };
}

/**
 * Get high priority alerts
 */
async function getHighPriorityAlerts(therapistId) {
    // Get all patients
    const { data: patients } = await supabase
        .from('patients')
        .select('id, first_name, last_name')
        .eq('therapist_id', therapistId);

    const patientIds = patients.map(p => p.id);
    const patientMap = new Map(patients.map(p => [p.id, p]));

    // Get HIGH severity flags
    const { data: flags, error } = await supabase
        .from('patient_flags')
        .select('*')
        .in('patient_id', patientIds)
        .eq('severity', 'HIGH')
        .is('resolved_at', null)
        .order('created_at', { ascending: false });

    if (error) {
        throw new Error(`Failed to fetch alerts: ${error.message}`);
    }

    return (flags || []).map(flag => {
        const patient = patientMap.get(flag.patient_id);
        return {
            id: flag.id,
            patient_id: flag.patient_id,
            patient_name: patient ? `${patient.first_name} ${patient.last_name}` : 'Unknown',
            flag_type: flag.flag_type,
            severity: flag.severity,
            description: flag.description,
            created_at: flag.created_at
        };
    });
}

export {
    searchPatients,
    getDashboardSummary,
    getHighPriorityAlerts
};
