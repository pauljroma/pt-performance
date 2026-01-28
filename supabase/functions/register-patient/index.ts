import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface RegisterRequest {
  userId: string;
  email: string;
  fullName: string;
  authProvider: "email" | "apple";
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, serviceRoleKey);

    const { userId, email, fullName, authProvider }: RegisterRequest = await req.json();

    if (!userId || !email || !fullName) {
      return new Response(
        JSON.stringify({ error: "Missing required fields: userId, email, fullName" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Parse name
    const nameParts = fullName.trim().split(" ");
    const firstName = nameParts[0] || "Patient";
    const lastName = nameParts.slice(1).join(" ") || "";

    // Check if patient already exists for this auth user
    const { data: existing } = await supabase
      .from("patients")
      .select("id")
      .eq("user_id", userId)
      .maybeSingle();

    if (existing) {
      return new Response(
        JSON.stringify({ patientId: existing.id, message: "Patient already registered" }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Create patient record (no therapist — independent registration)
    const { data: patient, error } = await supabase
      .from("patients")
      .insert({
        user_id: userId,
        email: email.toLowerCase(),
        first_name: firstName,
        last_name: lastName,
        sport: "General Fitness",
        position: null,
        therapist_id: null,
      })
      .select("id")
      .single();

    if (error) {
      console.error("Error creating patient:", error);
      return new Response(
        JSON.stringify({ error: "Failed to create patient record", details: error.message }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    return new Response(
      JSON.stringify({
        patientId: patient.id,
        message: "Patient registered successfully",
        authProvider,
      }),
      { status: 201, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    console.error("Unexpected error:", err);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
