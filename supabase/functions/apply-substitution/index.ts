// Apply Substitution Edge Function
// Applies AI exercise substitutions by updating session_exercises table
// BUILD 187 - Fixed to update session_exercises directly

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import { requireAuth, createAuthenticatedClient, verifyPatientOwnership, AuthUser } from '../_shared/auth.ts'

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

interface ApplySubstitutionRequest {
  recommendation_id: string;
}

// UUID validation helper
function isValidUUID(uuid: string): boolean {
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
  return uuidRegex.test(uuid);
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  // Authenticate user with JWT validation
  const authResult = await requireAuth(req)
  if (authResult instanceof Response) return authResult
  const authUser = authResult as AuthUser

  try {
    // Initialize Supabase client with user's JWT for RLS
    const supabase = createAuthenticatedClient(req)

    // Parse request body
    const body: ApplySubstitutionRequest = await req.json();
    const { recommendation_id } = body;

    console.log("BUILD 187: Applying substitution for recommendation_id:", recommendation_id);

    if (!recommendation_id) {
      throw new Error("recommendation_id is required");
    }

    // Validate UUID format
    if (!isValidUUID(recommendation_id)) {
      return new Response(
        JSON.stringify({ success: false, error: "Invalid recommendation_id format" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Fetch recommendation from database
    const { data: recommendation, error: recError } = await supabase
      .from("recommendations")
      .select("*")
      .eq("id", recommendation_id)
      .single();

    if (recError || !recommendation) {
      console.error("BUILD 187: Recommendation not found:", recError);
      throw new Error("Recommendation not found");
    }

    // Verify user owns this recommendation (via session → patient)
    const { data: session } = await supabase
      .from('sessions')
      .select('patient_id')
      .eq('id', recommendation.session_id)
      .maybeSingle()

    if (!session) {
      return new Response(
        JSON.stringify({ success: false, error: 'Session not found' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const isOwner = await verifyPatientOwnership(supabase, session.patient_id, authUser.user_id)
    if (!isOwner) {
      return new Response(
        JSON.stringify({ success: false, error: 'You do not have access to this recommendation' }),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    console.log("BUILD 187: Found recommendation, session_id:", recommendation.session_id);
    console.log("BUILD 187: Recommendation patch:", JSON.stringify(recommendation.patch));

    // Verify recommendation status is pending
    if (recommendation.status !== "pending") {
      throw new Error(
        `Recommendation cannot be applied (status: ${recommendation.status})`
      );
    }

    // Extract substitutions from the patch
    const patch = recommendation.patch;
    const substitutions = patch?.exercise_substitutions || patch?.substitutions || [];

    console.log("BUILD 187: Found", substitutions.length, "substitutions to apply");

    if (substitutions.length === 0) {
      throw new Error("No substitutions found in recommendation patch");
    }

    // Apply each substitution by updating session_exercises
    let appliedCount = 0;
    const errors: string[] = [];

    for (const sub of substitutions) {
      const originalExerciseId = sub.original_exercise_id;
      const substituteExerciseId = sub.substitute_exercise_id;

      console.log(`BUILD 187: Substituting ${originalExerciseId} -> ${substituteExerciseId}`);

      // Check if this is a bodyweight exercise (no equipment required)
      const isBodyweight = !sub.equipment_required || sub.equipment_required.length === 0;

      // Build update payload
      const updatePayload: Record<string, any> = {
        exercise_template_id: substituteExerciseId,
        notes: sub.reason ? `AI Substitution: ${sub.reason}` : null
      };

      // Clear load for bodyweight exercises
      if (isBodyweight) {
        updatePayload.prescribed_load = null;
        updatePayload.load_unit = "BW";
      }

      // Update session_exercises where session_id matches and exercise_template_id matches original
      const { data: updateResult, error: updateError } = await supabase
        .from("session_exercises")
        .update(updatePayload)
        .eq("session_id", recommendation.session_id)
        .eq("exercise_template_id", originalExerciseId)
        .select();

      if (updateError) {
        console.error(`BUILD 187: Error updating exercise ${originalExerciseId}:`, updateError);
        errors.push(`Failed to update ${originalExerciseId}: ${updateError.message}`);
      } else {
        const rowsUpdated = updateResult?.length || 0;
        console.log(`BUILD 187: Updated ${rowsUpdated} rows for ${originalExerciseId}`);
        appliedCount += rowsUpdated;
      }
    }

    // Update recommendation status to applied
    const { error: updateRecError } = await supabase
      .from("recommendations")
      .update({
        status: "applied",
        applied_at: new Date().toISOString(),
      })
      .eq("id", recommendation_id);

    if (updateRecError) {
      console.error("BUILD 187: Error updating recommendation status:", updateRecError);
      // Don't throw - the substitutions were applied, just status update failed
    }

    console.log(`BUILD 187: Successfully applied ${appliedCount} substitutions`);

    return new Response(
      JSON.stringify({
        success: true,
        message: `Applied ${appliedCount} substitutions successfully`,
        applied_count: appliedCount,
        recommendation_id: recommendation_id,
        errors: errors.length > 0 ? errors : undefined,
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      }
    );
  } catch (error) {
    console.error("BUILD 187: Error in apply-substitution:", error);

    return new Response(
      JSON.stringify({
        success: false,
        error: error.message || "Internal server error",
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: error.message?.includes("not found") ? 404 : 400,
      }
    );
  }
});
