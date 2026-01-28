import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface ValidateReceiptRequest {
  transactionId: string;
  originalTransactionId: string;
  productId: string;
  patientId: string;
  expiresAt: string;
  environment: "production" | "sandbox";
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, serviceRoleKey);

    const body: ValidateReceiptRequest = await req.json();

    if (!body.transactionId || !body.productId || !body.patientId) {
      return new Response(
        JSON.stringify({ error: "Missing required fields" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Upsert subscription record
    const { data, error } = await supabase
      .from("subscriptions")
      .upsert(
        {
          patient_id: body.patientId,
          product_id: body.productId,
          original_transaction_id: body.originalTransactionId,
          status: "active",
          expires_at: body.expiresAt,
          environment: body.environment || "production",
          updated_at: new Date().toISOString(),
        },
        { onConflict: "patient_id" }
      )
      .select()
      .single();

    if (error) {
      console.error("Error upserting subscription:", error);
      return new Response(
        JSON.stringify({ error: "Failed to update subscription", details: error.message }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    return new Response(
      JSON.stringify({
        subscription: data,
        status: "active",
        message: "Subscription validated and recorded",
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    console.error("Unexpected error:", err);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
