import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

function generateCode(): string {
  const chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"; // No I, O, 0, 1 to avoid confusion
  let code = "";
  for (let i = 0; i < 8; i++) {
    code += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return code;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, serviceRoleKey);

    const { action, patientId, therapistId, code } = await req.json();

    if (action === "generate") {
      // Patient generates a linking code
      if (!patientId) {
        return new Response(
          JSON.stringify({ error: "patientId required" }),
          { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
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

      // Find valid, unused code
      const { data: linkingCode, error: findError } = await supabase
        .from("linking_codes")
        .select("*")
        .eq("code", code.toUpperCase())
        .is("used_by", null)
        .gt("expires_at", new Date().toISOString())
        .maybeSingle();

      if (findError || !linkingCode) {
        return new Response(
          JSON.stringify({ error: "Invalid or expired linking code" }),
          { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      // Update patient's therapist_id
      const { error: updateError } = await supabase
        .from("patients")
        .update({ therapist_id: therapistId })
        .eq("id", linkingCode.patient_id);

      if (updateError) {
        console.error("Error linking therapist:", updateError);
        return new Response(
          JSON.stringify({ error: "Failed to link therapist" }),
          { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      // Mark code as used
      await supabase
        .from("linking_codes")
        .update({ used_by: therapistId })
        .eq("id", linkingCode.id);

      return new Response(
        JSON.stringify({
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
