import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { requireAuth, createAuthenticatedClient, verifyPatientOwnership, AuthUser } from '../_shared/auth.ts'

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

function generateCode(): string {
  const chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"; // 32 chars (no I, O, 0, 1)
  const randomBytes = new Uint8Array(8);
  crypto.getRandomValues(randomBytes);  // Cryptographically secure

  return Array.from(randomBytes)
    .map(byte => chars[byte % chars.length])
    .join('');
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Require authentication for all actions
    const authResult = await requireAuth(req)
    if (authResult instanceof Response) return authResult
    const authUser = authResult as AuthUser

    const supabase = createAuthenticatedClient(req)

    const { action, patientId, therapistId, code } = await req.json();

    if (action === "generate") {
      // Patient generates a linking code
      if (!patientId) {
        return new Response(
          JSON.stringify({ error: "patientId required" }),
          { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      // Verify user owns the patient record
      const isOwner = await verifyPatientOwnership(supabase, patientId, authUser.user_id);
      if (!isOwner) {
        return new Response(
          JSON.stringify({ error: "You do not own this patient record" }),
          { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      const linkCode = generateCode();
      const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(); // 24 hours

      // Upsert (replace existing code for this patient)
      const { data, error } = await supabase
        .from("linking_codes")
        .upsert(
          {
            patient_id: patientId,
            code: linkCode,
            expires_at: expiresAt,
            used_by: null,
          },
          { onConflict: "patient_id" }
        )
        .select()
        .single();

      if (error) {
        console.error("Error generating code:", error);
        return new Response(
          JSON.stringify({ error: "Failed to generate linking code" }),
          { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      return new Response(
        JSON.stringify({ code: linkCode, expiresAt }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (action === "link") {
      // Therapist enters code to link with patient
      if (!therapistId || !code) {
        return new Response(
          JSON.stringify({ error: "therapistId and code required" }),
          { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      // Verify therapist_id matches authenticated user (therapists link themselves)
      if (therapistId !== authUser.user_id) {
        return new Response(
          JSON.stringify({ error: "Cannot link as another therapist" }),
          { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      // ATOMIC: Claim the code in a single operation
      // This prevents race conditions - only one request can succeed
      const { data: linkingCode, error: claimError } = await supabase
        .from("linking_codes")
        .update({
          used_by: therapistId,
          used_at: new Date().toISOString()
        })
        .eq("code", code.toUpperCase())
        .is("used_by", null)  // Only if not already used
        .gt("expires_at", new Date().toISOString())  // Only if not expired
        .select("id, patient_id, code")
        .single();

      if (claimError || !linkingCode) {
        return new Response(
          JSON.stringify({ error: "Invalid, expired, or already used linking code" }),
          { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      // Now safe to update patient - we have exclusive claim on the code
      const { error: updateError } = await supabase
        .from("patients")
        .update({ therapist_id: therapistId })
        .eq("id", linkingCode.patient_id);

      if (updateError) {
        // Rollback: release the code
        await supabase
          .from("linking_codes")
          .update({ used_by: null, used_at: null })
          .eq("id", linkingCode.id);

        console.error("Error linking therapist:", updateError);
        return new Response(
          JSON.stringify({ error: "Failed to link therapist", details: updateError.message }),
          { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      return new Response(
        JSON.stringify({
          success: true,
          message: "Therapist linked successfully",
          patientId: linkingCode.patient_id,
        }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (action === "unlink") {
      // Patient unlinks from therapist
      if (!patientId) {
        return new Response(
          JSON.stringify({ error: "patientId required" }),
          { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      // Verify user owns the patient record
      const isOwner = await verifyPatientOwnership(supabase, patientId, authUser.user_id);
      if (!isOwner) {
        return new Response(
          JSON.stringify({ error: "You do not own this patient record" }),
          { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      const { error } = await supabase
        .from("patients")
        .update({ therapist_id: null })
        .eq("id", patientId);

      if (error) {
        return new Response(
          JSON.stringify({ error: "Failed to unlink therapist" }),
          { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      return new Response(
        JSON.stringify({ message: "Therapist unlinked successfully" }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    return new Response(
      JSON.stringify({ error: "Invalid action. Use: generate, link, or unlink" }),
      { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    console.error("Unexpected error:", err);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
