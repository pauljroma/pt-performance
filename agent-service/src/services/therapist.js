import { createClient } from '@supabase/supabase-js';
import { config } from '../config.js';

const supabase = createClient(config.supabase.url, config.supabase.serviceKey);

function sanitizeSearchTerm(value) {
    return String(value)
        .replace(/[,%()]/g, ' ')
        .trim()
        .replace(/\s+/g, ' ');
}

function buildPatientMetrics(patients, adherenceRows, latestSessionsByPatientRows) {
    const adherenceByPatientId = new Map((adherenceRows || []).map((row) => [row.patient_id, row]));
    const latestSessionByPatientId = new Map((latestSessionsByPatientRows || []).map((row) => [row.patient_id, row]));

    return patients.map((patient) => {
        const flags = patient.patient_flags || [];
        const highSeverityFlags = flags.filter((flag) => flag.severity === 'HIGH').length;
        const mediumSeverityFlags = flags.filter((flag) => flag.severity === 'MEDIUM').length;
        const lowSeverityFlags = flags.filter((flag) => flag.severity === 'LOW').length;
        const totalFlags = flags.length;

        const adherenceData = adherenceByPatientId.get(patient.id);
        const lastSession = latestSessionByPatientId.get(patient.id);

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
            adherence_percentage: adherenceData?.adherence_pct || 0,
            completed_sessions: adherenceData?.completed_sessions || 0,
            total_sessions: adherenceData?.total_sessions || 0,
            last_session_date: lastSession?.session_date || null,
        };
    });
}

async function getLatestSessionsByPatient(patientIds) {
    const { data, error } = await supabase
        .from('patients')
        .select('id, sessions(session_date)')
        .in('id', patientIds)
        .order('session_date', { foreignTable: 'sessions', ascending: false })
        .limit(1, { foreignTable: 'sessions' });

    if (error) {
        throw new Error(`Failed to fetch latest session data: ${error.message}`);
    }

    return (data || []).map((row) => ({
        patient_id: row.id,
        session_date: row.sessions?.[0]?.session_date || null,
    }));
}

async function searchPatients(filters) {
    let query = supabase
        .from('patients')
        .select(
            `
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
        `,
            { count: 'exact' }
        )
        .eq('therapist_id', filters.therapistId);

    if (filters.search) {
        const sanitizedSearch = sanitizeSearchTerm(filters.search);

        if (sanitizedSearch) {
            query = query.or(
                `first_name.ilike.%${sanitizedSearch}%,last_name.ilike.%${sanitizedSearch}%,email.ilike.%${sanitizedSearch}%`
            );
        }
    }

    if (filters.sport) {
        query = query.eq('sport', filters.sport);
    }

    if (filters.position) {
        query = query.eq('position', filters.position);
    }

    const { data: patients, error, count } = await query;

    if (error) {
        throw new Error(`Failed to fetch patients: ${error.message}`);
    }

    if (!patients?.length) {
        return {
            patients: [],
            totalCount: 0,
            offset: filters.offset,
            limit: filters.limit,
        };
    }

    const patientIds = patients.map((patient) => patient.id);

    const [{ data: adherenceRows, error: adherenceError }, latestSessionsByPatientRows] = await Promise.all([
        supabase
            .from('vw_patient_adherence')
            .select('patient_id, adherence_pct, completed_sessions, total_sessions')
            .in('patient_id', patientIds),
        getLatestSessionsByPatient(patientIds),
    ]);

    if (adherenceError) {
        throw new Error(`Failed to fetch adherence data: ${adherenceError.message}`);
    }

    const enrichedPatients = buildPatientMetrics(patients, adherenceRows, latestSessionsByPatientRows);

    let filteredPatients = enrichedPatients;

    if (filters.flagSeverity) {
        const severityKey = `${filters.flagSeverity.toLowerCase()}_severity_flag_count`;
        filteredPatients = filteredPatients.filter((patient) => patient[severityKey] > 0);
    }

    if (filters.hasFlags !== null) {
        filteredPatients = filteredPatients.filter((patient) =>
            filters.hasFlags ? patient.flag_count > 0 : patient.flag_count === 0
        );
    }

    if (filters.minAdherence !== null) {
        filteredPatients = filteredPatients.filter((patient) => patient.adherence_percentage >= filters.minAdherence);
    }

    if (filters.maxAdherence !== null) {
        filteredPatients = filteredPatients.filter((patient) => patient.adherence_percentage <= filters.maxAdherence);
    }

    filteredPatients.sort((a, b) => {
        if (b.high_severity_flag_count !== a.high_severity_flag_count) {
            return b.high_severity_flag_count - a.high_severity_flag_count;
        }
        return a.last_name.localeCompare(b.last_name);
    });

    const paginatedPatients = filteredPatients.slice(filters.offset, filters.offset + filters.limit);

    return {
        patients: paginatedPatients,
        totalCount: filteredPatients.length || count || 0,
        offset: filters.offset,
        limit: filters.limit,
    };
}

async function getDashboardSummary(therapistId) {
    const { data: patients, error: patientsError } = await supabase
        .from('patients')
        .select('id')
        .eq('therapist_id', therapistId);

    if (patientsError) {
        throw new Error(`Failed to fetch patients: ${patientsError.message}`);
    }

    const patientIds = (patients || []).map((patient) => patient.id);

    if (!patientIds.length) {
        return {
            total_patients: 0,
            high_severity_flags: 0,
            avg_adherence: 0,
            sessions_this_week: { completed: 0, total: 0 },
            patients_at_risk: 0,
        };
    }

    const { data: highSeverityFlags, error: flagsError } = await supabase
        .from('patient_flags')
        .select('id, patient_id, flag_type, description')
        .in('patient_id', patientIds)
        .eq('severity', 'HIGH')
        .is('resolved_at', null);

    if (flagsError) {
        throw new Error(`Failed to fetch flags: ${flagsError.message}`);
    }

    const { data: adherenceRows, error: adherenceError } = await supabase
        .from('vw_patient_adherence')
        .select('patient_id, adherence_pct')
        .in('patient_id', patientIds);

    if (adherenceError) {
        throw new Error(`Failed to fetch adherence summary: ${adherenceError.message}`);
    }

    const adherenceValues = (adherenceRows || []).map((row) => row.adherence_pct || 0);
    const avgAdherence = adherenceValues.length > 0
        ? adherenceValues.reduce((sum, value) => sum + value, 0) / adherenceValues.length
        : 0;

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

    const completedThisWeek = sessionData?.filter((session) => session.completed).length || 0;
    const totalThisWeek = sessionData?.length || 0;

    return {
        total_patients: patients.length,
        high_severity_flags: highSeverityFlags?.length || 0,
        avg_adherence: Math.round(avgAdherence * 10) / 10,
        sessions_this_week: { completed: completedThisWeek, total: totalThisWeek },
        patients_at_risk: highSeverityFlags?.length || 0,
    };
}

async function getHighPriorityAlerts(therapistId) {
    const { data: patients, error: patientsError } = await supabase
        .from('patients')
        .select('id, first_name, last_name')
        .eq('therapist_id', therapistId);

    if (patientsError) {
        throw new Error(`Failed to fetch therapist patients: ${patientsError.message}`);
    }

    const patientIds = (patients || []).map((patient) => patient.id);
    const patientMap = new Map((patients || []).map((patient) => [patient.id, patient]));

    if (!patientIds.length) {
        return [];
    }

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

    return (flags || []).map((flag) => {
        const patient = patientMap.get(flag.patient_id);
        return {
            id: flag.id,
            patient_id: flag.patient_id,
            patient_name: patient ? `${patient.first_name} ${patient.last_name}` : 'Unknown',
            flag_type: flag.flag_type,
            severity: flag.severity,
            description: flag.description,
            created_at: flag.created_at,
        };
    });
}

export {
    searchPatients,
    getDashboardSummary,
    getHighPriorityAlerts,
    buildPatientMetrics,
    sanitizeSearchTerm,
    getLatestSessionsByPatient,
};
