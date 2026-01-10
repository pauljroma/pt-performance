// Trigger Readiness Adjustment Edge Function
// Automatically creates workout adjustments when daily readiness is submitted
// ACP-217: Add adjustment Edge Function
// Build 72 - Agent 3: Backend Lead - Adjustment Algorithm

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

interface DailyReadiness {
  id: string;
  patient_id: string;
  check_in_date: string;
  readiness_band: "green" | "yellow" | "orange" | "red";
  readiness_score?: number;
  whoop_recovery_pct?: number;
  subjective_readiness?: number;
  sleep_hours?: number;
  sleep_quality?: number;
}

interface TriggerRequest {
  daily_readiness_id: string;
  patient_id?: string; // Optional - will be fetched from daily_readiness if not provided
  force_recalculate?: boolean; // Force recalculation even if adjustment exists
}

interface TriggerResponse {
  success: boolean;
  adjustment_id?: string;
  readiness_band: string;
  load_adjustment_pct: number;
  volume_adjustment_pct: number;
  skip_top_set: boolean;
  technique_only: boolean;
  message: string;
  scheduled_session_id?: string;
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    // Initialize Supabase client
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Authenticate request
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      throw new Error("Missing authorization header");
    }

    const token = authHeader.replace("Bearer ", "");
    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser(token);

    if (authError || !user) {
      throw new Error("Unauthorized");
    }

    // Parse request body
    const body: TriggerRequest = await req.json();
    const { daily_readiness_id, patient_id, force_recalculate } = body;

    if (!daily_readiness_id) {
      throw new Error("daily_readiness_id is required");
    }

    // Fetch daily readiness record
    const { data: dailyReadiness, error: readinessError } = await supabase
      .from("daily_readiness")
      .select("*")
      .eq("id", daily_readiness_id)
      .single();

    if (readinessError || !dailyReadiness) {
      throw new Error(
        `Daily readiness not found: ${readinessError?.message || "Unknown error"}`
      );
    }

    const targetPatientId = patient_id || dailyReadiness.patient_id;

    // Verify user has access to this patient
    const { data: patient, error: patientError } = await supabase
      .from("patients")
      .select("id, user_id, therapist_id, auto_adjustment_enabled")
      .eq("id", targetPatientId)
      .single();

    if (patientError || !patient) {
      throw new Error("Patient not found or access denied");
    }

    // Check if user is the patient or their therapist
    const { data: therapist } = await supabase
      .from("therapists")
      .select("id")
      .eq("user_id", user.id)
      .single();

    const isPatient = patient.user_id === user.id;
    const isTherapist = therapist && patient.therapist_id === therapist.id;

    if (!isPatient && !isTherapist) {
      throw new Error("Access denied: not patient or assigned therapist");
    }

    // Check if patient has auto-adjustment enabled
    if (!patient.auto_adjustment_enabled) {
      return new Response(
        JSON.stringify({
          success: false,
          message: "Auto-adjustment is disabled for this patient",
          readiness_band: dailyReadiness.readiness_band,
          load_adjustment_pct: 0,
          volume_adjustment_pct: 0,
          skip_top_set: false,
          technique_only: false,
        }),
        {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
          status: 200,
        }
      );
    }

    // Find scheduled session for today
    const checkInDate = new Date(dailyReadiness.check_in_date);
    const { data: scheduledSessions, error: sessionError } = await supabase
      .from("scheduled_sessions")
      .select("id, session_id")
      .eq("patient_id", targetPatientId)
      .eq("scheduled_date", dailyReadiness.check_in_date)
      .eq("status", "scheduled")
      .limit(1);

    if (sessionError) {
      console.error("Error fetching scheduled sessions:", sessionError);
    }

    const scheduledSession = scheduledSessions?.[0];

    if (!scheduledSession) {
      // No session scheduled for today, no adjustment needed
      return new Response(
        JSON.stringify({
          success: true,
          message:
            "No scheduled session found for today - no adjustment needed",
          readiness_band: dailyReadiness.readiness_band,
          load_adjustment_pct: 0,
          volume_adjustment_pct: 0,
          skip_top_set: false,
          technique_only: false,
        }),
        {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
          status: 200,
        }
      );
    }

    // Check if adjustment already exists
    if (!force_recalculate) {
      const { data: existingAdjustment } = await supabase
        .from("readiness_adjustments")
        .select("*")
        .eq("patient_id", targetPatientId)
        .eq("session_id", scheduledSession.session_id)
        .single();

      if (existingAdjustment && !existingAdjustment.was_overridden) {
        // Return existing adjustment
        return new Response(
          JSON.stringify({
            success: true,
            adjustment_id: existingAdjustment.id,
            readiness_band: existingAdjustment.readiness_band,
            load_adjustment_pct: existingAdjustment.load_adjustment_pct,
            volume_adjustment_pct: existingAdjustment.volume_adjustment_pct,
            skip_top_set: existingAdjustment.skip_top_set,
            technique_only: existingAdjustment.technique_only,
            message: "Existing adjustment found",
            scheduled_session_id: scheduledSession.id,
          }),
          {
            headers: { ...corsHeaders, "Content-Type": "application/json" },
            status: 200,
          }
        );
      }
    }

    // Call database function to create adjustment
    const { data: adjustmentId, error: createError } = await supabase.rpc(
      "calculate_readiness_adjustment",
      {
        p_patient_id: targetPatientId,
        p_session_id: scheduledSession.session_id,
        p_readiness_band: dailyReadiness.readiness_band,
        p_daily_readiness_id: daily_readiness_id,
      }
    );

    if (createError) {
      console.error("Error creating adjustment:", createError);
      throw new Error(`Failed to create adjustment: ${createError.message}`);
    }

    if (!adjustmentId) {
      throw new Error(
        "Adjustment calculation returned null - may be disabled for patient"
      );
    }

    // Fetch the created adjustment
    const { data: adjustment, error: fetchError } = await supabase
      .from("readiness_adjustments")
      .select("*")
      .eq("id", adjustmentId)
      .single();

    if (fetchError || !adjustment) {
      throw new Error("Failed to fetch created adjustment");
    }

    // Send notification if Red band (suggest rest)
    if (dailyReadiness.readiness_band === "red") {
      try {
        // Call push notification function
        await supabase.functions.invoke("send-push-notification", {
          body: {
            patient_id: targetPatientId,
            title: "Rest Day Recommended",
            body: "Your readiness is low today. Consider taking a rest day or doing technique work only.",
            data: {
              type: "readiness_alert",
              adjustment_id: adjustmentId,
              readiness_band: "red",
            },
          },
        });
      } catch (notifError) {
        console.error("Failed to send push notification:", notifError);
        // Don't fail the whole request if notification fails
      }
    }

    // Format response
    const response: TriggerResponse = {
      success: true,
      adjustment_id: adjustment.id,
      readiness_band: adjustment.readiness_band,
      load_adjustment_pct: adjustment.load_adjustment_pct,
      volume_adjustment_pct: adjustment.volume_adjustment_pct,
      skip_top_set: adjustment.skip_top_set,
      technique_only: adjustment.technique_only,
      message: "Adjustment created successfully",
      scheduled_session_id: scheduledSession.id,
    };

    return new Response(JSON.stringify(response), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 200,
    });
  } catch (error) {
    console.error("Error in trigger-readiness-adjustment:", error);

    return new Response(
      JSON.stringify({
        success: false,
        error: error.message || "Internal server error",
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: error.message?.includes("Unauthorized") ||
            error.message?.includes("Access denied")
          ? 401
          : 400,
      }
    );
  }
});
