// Demo Auth Edge Function
// Creates a real Supabase Auth session for demo/test users.
//
// This allows demo mode in the iOS app to use proper auth.uid() scoping
// instead of bypassing authentication, which caused all RLS policies
// to be opened to USING(true).
//
// SECURITY:
// - ONLY works when DEMO_MODE_ENABLED env var is "true"
// - Returns 403 in production
// - Only accepts known demo user UUIDs (from seeded test data)
// - Uses Supabase Admin API to generate tokens (service_role key)

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

// Known demo user UUIDs (must match seeded test data)
// Therapist
const DEMO_THERAPIST_ID = "00000000-0000-0000-0000-000000000100";

// Original demo patient (John Brebbia)
const DEMO_PATIENT_LEGACY = "00000000-0000-0000-0000-000000000001";

// 10 test persona patients (Marcus, Alyssa, Tyler, etc.)
const DEMO_PATIENTS = [
  "aaaaaaaa-bbbb-cccc-dddd-000000000001",
  "aaaaaaaa-bbbb-cccc-dddd-000000000002",
  "aaaaaaaa-bbbb-cccc-dddd-000000000003",
  "aaaaaaaa-bbbb-cccc-dddd-000000000004",
  "aaaaaaaa-bbbb-cccc-dddd-000000000005",
  "aaaaaaaa-bbbb-cccc-dddd-000000000006",
  "aaaaaaaa-bbbb-cccc-dddd-000000000007",
  "aaaaaaaa-bbbb-cccc-dddd-000000000008",
  "aaaaaaaa-bbbb-cccc-dddd-000000000009",
  "aaaaaaaa-bbbb-cccc-dddd-00000000000a",
];

const KNOWN_DEMO_UUIDS = new Set([
  DEMO_THERAPIST_ID,
  DEMO_PATIENT_LEGACY,
  ...DEMO_PATIENTS,
]);

// Deterministic email for demo users (used as auth.users email)
function demoEmail(uuid: string): string {
  return `demo-${uuid.slice(-4)}@ptperformance.test`;
}

// Deterministic password for demo users (not secret -- demo only)
const DEMO_PASSWORD = "demo-mode-test-2026!";

interface DemoAuthRequest {
  demo_user_id: string;
  role?: "patient" | "therapist";
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // ================================================================
    // GATE 1: Environment check -- demo mode must be explicitly enabled
    // ================================================================
    const demoEnabled = Deno.env.get("DEMO_MODE_ENABLED");
    if (demoEnabled !== "true") {
      console.warn(
        "demo-auth called but DEMO_MODE_ENABLED is not 'true'. Returning 403."
      );
      return new Response(
        JSON.stringify({
          error: "Forbidden",
          message: "Demo mode is not enabled in this environment",
        }),
        {
          status: 403,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // ================================================================
    // GATE 2: Parse and validate the request
    // ================================================================
    const body: DemoAuthRequest = await req.json();
    const { demo_user_id, role } = body;

    if (!demo_user_id) {
      return new Response(
        JSON.stringify({
          error: "Bad Request",
          message: "demo_user_id is required",
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // ================================================================
    // GATE 3: Validate it is a known demo UUID
    // ================================================================
    const normalizedId = demo_user_id.toLowerCase();
    if (!KNOWN_DEMO_UUIDS.has(normalizedId)) {
      console.warn(`demo-auth: rejected unknown UUID: ${normalizedId}`);
      return new Response(
        JSON.stringify({
          error: "Forbidden",
          message: "Not a recognized demo user UUID",
        }),
        {
          status: 403,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // ================================================================
    // Create admin client with service_role key
    // ================================================================
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const adminClient = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });

    const email = demoEmail(normalizedId);

    // ================================================================
    // Ensure the auth.users record exists for this demo user
    // We create it with admin API if it does not exist yet.
    // ================================================================
    let authUserId: string;

    // Try to find existing auth user by email
    const { data: existingUsers, error: listError } =
      await adminClient.auth.admin.listUsers();

    const existingUser = existingUsers?.users?.find(
      (u) => u.email === email
    );

    if (existingUser) {
      authUserId = existingUser.id;
    } else {
      // Create the auth user with the demo UUID as the id
      // We use the admin API to set a specific UUID
      const { data: newUser, error: createError } =
        await adminClient.auth.admin.createUser({
          email,
          password: DEMO_PASSWORD,
          email_confirm: true,
          user_metadata: {
            demo_user: true,
            demo_db_id: normalizedId,
            role: role || (normalizedId === DEMO_THERAPIST_ID ? "therapist" : "patient"),
          },
        });

      if (createError) {
        console.error("Failed to create demo auth user:", createError);
        return new Response(
          JSON.stringify({
            error: "Internal Error",
            message: "Failed to create demo auth user",
            details: createError.message,
          }),
          {
            status: 500,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }

      authUserId = newUser.user!.id;

      // Link the auth user to the demo DB record
      // Update the patients/therapists table to set user_id = auth user id
      if (normalizedId === DEMO_THERAPIST_ID) {
        await adminClient
          .from("therapists")
          .update({ user_id: authUserId })
          .eq("id", normalizedId);
      } else {
        await adminClient
          .from("patients")
          .update({ user_id: authUserId })
          .eq("id", normalizedId);
      }

      console.log(
        `demo-auth: Created auth user ${authUserId} for demo DB record ${normalizedId}`
      );
    }

    // ================================================================
    // Generate a session (sign in as the demo user)
    // We use admin.generateLink which gives us tokens directly
    // ================================================================

    // Use signInWithPassword via a temporary anon client
    // This is the cleanest way to get a real session the iOS SDK can consume
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
    const anonClient = createClient(supabaseUrl, anonKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });

    const { data: signInData, error: signInError } =
      await anonClient.auth.signInWithPassword({
        email,
        password: DEMO_PASSWORD,
      });

    if (signInError || !signInData.session) {
      console.error("Failed to sign in demo user:", signInError);
      return new Response(
        JSON.stringify({
          error: "Internal Error",
          message: "Failed to generate demo session",
          details: signInError?.message || "No session returned",
        }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const session = signInData.session;

    console.log(
      `demo-auth: Session created for ${email} (auth: ${authUserId}, db: ${normalizedId})`
    );

    // ================================================================
    // Return the session tokens to the iOS client
    // ================================================================
    return new Response(
      JSON.stringify({
        access_token: session.access_token,
        refresh_token: session.refresh_token,
        expires_in: session.expires_in,
        expires_at: session.expires_at,
        token_type: session.token_type,
        user: {
          id: session.user.id,
          email: session.user.email,
          role: session.user.role,
        },
        // App-level metadata for the iOS client
        demo_db_id: normalizedId,
        demo_role:
          role || (normalizedId === DEMO_THERAPIST_ID ? "therapist" : "patient"),
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (err) {
    console.error("demo-auth: Unexpected error:", err);
    return new Response(
      JSON.stringify({
        error: "Internal Server Error",
        message: String(err),
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
