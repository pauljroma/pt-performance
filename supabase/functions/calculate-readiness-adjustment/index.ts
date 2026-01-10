// Calculate Readiness Adjustment Edge Function
// Processes readiness band and generates workout adjustments
// ACP-215, ACP-216, ACP-217
// Build 72 - Agent 3: Backend Lead - Adjustment Algorithm

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

interface AdjustmentRequest {
  patient_id: string;
  session_id: string;
  readiness_band: "green" | "yellow" | "orange" | "red";
  daily_readiness_id?: string;
  force_recalculate?: boolean;
}

interface AdjustmentResponse {
  adjustment_id: string;
  patient_id: string;
  session_id: string;
  readiness_band: string;
  load_adjustment_pct: number;
  volume_adjustment_pct: number;
  skip_top_set: boolean;
  technique_only: boolean;
  applied_at: string;
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
    const body: AdjustmentRequest = await req.json();
    const {
      patient_id,
      session_id,
      readiness_band,
      daily_readiness_id,
      force_recalculate,
    } = body;

    if (!patient_id) {
      throw new Error("patient_id is required");
    }

    if (!session_id) {
      throw new Error("session_id is required");
    }

    if (!readiness_band) {
      throw new Error("readiness_band is required");
    }

    // Verify user has access to this patient
    const { data: patient, error: patientError } = await supabase
      .from("patients")
      .select("id, user_id, therapist_id, auto_adjustment_enabled")
      .eq("id", patient_id)
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
      throw new Error("Auto-adjustment is disabled for this patient");
    }

    // Check if adjustment already exists
    if (!force_recalculate) {
      const { data: existingAdjustment } = await supabase
        .from("readiness_adjustments")
        .select("*")
        .eq("patient_id", patient_id)
        .eq("session_id", session_id)
        .single();

      if (existingAdjustment && !existingAdjustment.was_overridden) {
        // Return existing adjustment
        return new Response(
          JSON.stringify({
            success: true,
            adjustment: {
              adjustment_id: existingAdjustment.id,
              patient_id: existingAdjustment.patient_id,
              session_id: existingAdjustment.session_id,
              readiness_band: existingAdjustment.readiness_band,
              load_adjustment_pct: existingAdjustment.load_adjustment_pct,
              volume_adjustment_pct: existingAdjustment.volume_adjustment_pct,
              skip_top_set: existingAdjustment.skip_top_set,
              technique_only: existingAdjustment.technique_only,
              applied_at: existingAdjustment.applied_at,
            },
            message: "Existing adjustment found",
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
        p_patient_id: patient_id,
        p_session_id: session_id,
        p_readiness_band: readiness_band,
        p_daily_readiness_id: daily_readiness_id || null,
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

    // Format response
    const response: AdjustmentResponse = {
      adjustment_id: adjustment.id,
      patient_id: adjustment.patient_id,
      session_id: adjustment.session_id,
      readiness_band: adjustment.readiness_band,
      load_adjustment_pct: adjustment.load_adjustment_pct,
      volume_adjustment_pct: adjustment.volume_adjustment_pct,
      skip_top_set: adjustment.skip_top_set,
      technique_only: adjustment.technique_only,
      applied_at: adjustment.applied_at,
    };

    return new Response(
      JSON.stringify({
        success: true,
        adjustment: response,
        message: "Adjustment calculated successfully",
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      }
    );
  } catch (error) {
    console.error("Error in calculate-readiness-adjustment:", error);

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
