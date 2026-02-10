import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient, SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";
import { requireAuth, AuthUser } from '../_shared/auth.ts'

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

/**
 * Creates a default "Getting Started" program for new patients.
 * This ensures new users have something to do immediately after registration.
 *
 * Structure:
 * - 1 Program: "Getting Started" (1 week)
 * - 1 Phase: "Week 1 - Foundation"
 * - 3 Sessions with basic exercises
 */
async function createStarterProgram(
  supabase: SupabaseClient,
  patientId: string
): Promise<{ success: boolean; programId?: string; error?: string }> {
  try {
    const today = new Date();
    const endDate = new Date(today);
    endDate.setDate(endDate.getDate() + 7); // 1 week program

    // 1. Create the program
    const { data: program, error: programError } = await supabase
      .from("programs")
      .insert({
        patient_id: patientId,
        name: "Getting Started",
        description: "A beginner-friendly introduction to fitness. Complete these foundational exercises to build strength, mobility, and healthy movement patterns.",
        start_date: today.toISOString().split("T")[0],
        end_date: endDate.toISOString().split("T")[0],
        status: "active",
        metadata: {
          frequency_per_week: 3,
          target_level: "Beginner",
          program_type: "starter",
          is_default_starter: true,
        },
      })
      .select("id")
      .single();

    if (programError) {
      console.error("Error creating starter program:", programError);
      return { success: false, error: programError.message };
    }

    // 2. Create the phase
    const { data: phase, error: phaseError } = await supabase
      .from("phases")
      .insert({
        program_id: program.id,
        name: "Week 1 - Foundation",
        sequence: 1,
        start_date: today.toISOString().split("T")[0],
        end_date: endDate.toISOString().split("T")[0],
        duration_weeks: 1,
        goals: "Build foundational movement patterns, establish exercise habits, and learn proper form.",
        constraints: {
          max_intensity_pct: 60,
          rpe_range: [4, 6],
          focus: "form_over_load",
        },
        notes: "Focus on learning the movements. Light weight, controlled tempo.",
      })
      .select("id")
      .single();

    if (phaseError) {
      console.error("Error creating starter phase:", phaseError);
      // Clean up the program since phase failed
      await supabase.from("programs").delete().eq("id", program.id);
      return { success: false, error: phaseError.message };
    }

    // 3. Create the sessions
    const sessionsData = [
      {
        phase_id: phase.id,
        name: "Full Body Basics",
        sequence: 1,
        weekday: 1, // Monday
        intensity_rating: 5,
        is_throwing_day: false,
        notes: "A balanced full-body workout using bodyweight and light resistance. Perfect for building a foundation.",
      },
      {
        phase_id: phase.id,
        name: "Core & Mobility",
        sequence: 2,
        weekday: 3, // Wednesday
        intensity_rating: 4,
        is_throwing_day: false,
        notes: "Focus on core stability and joint mobility. Essential for injury prevention and movement quality.",
      },
      {
        phase_id: phase.id,
        name: "Active Recovery",
        sequence: 3,
        weekday: 5, // Friday
        intensity_rating: 3,
        is_throwing_day: false,
        notes: "Light movement to promote recovery. Focus on blood flow and gentle stretching.",
      },
    ];

    const { data: sessions, error: sessionsError } = await supabase
      .from("sessions")
      .insert(sessionsData)
      .select("id, name");

    if (sessionsError) {
      console.error("Error creating starter sessions:", sessionsError);
      // Clean up program and phase
      await supabase.from("programs").delete().eq("id", program.id);
      return { success: false, error: sessionsError.message };
    }

    // 4. Create exercise templates for starter exercises (if they don't exist)
    // These are generic bodyweight exercises that work for any patient
    const starterExercises = [
      // Full Body Basics exercises
      { name: "Bodyweight Squat", category: "strength", body_region: "lower_body", equipment: "none", load_type: "bodyweight", cueing: "Feet shoulder-width apart, chest up, sit back like sitting in a chair" },
      { name: "Push-up (or Modified)", category: "strength", body_region: "upper_body", equipment: "none", load_type: "bodyweight", cueing: "Hands slightly wider than shoulders, body in straight line, lower chest to floor" },
      { name: "Glute Bridge", category: "strength", body_region: "lower_body", equipment: "none", load_type: "bodyweight", cueing: "Feet flat, drive through heels, squeeze glutes at top" },
      { name: "Bird Dog", category: "core", body_region: "core", equipment: "none", load_type: "bodyweight", cueing: "Opposite arm and leg, keep spine neutral, move slowly" },
      // Core & Mobility exercises
      { name: "Plank Hold", category: "core", body_region: "core", equipment: "none", load_type: "bodyweight", cueing: "Forearms on ground, body straight, engage core, breathe" },
      { name: "Dead Bug", category: "core", body_region: "core", equipment: "none", load_type: "bodyweight", cueing: "Back flat on floor, opposite arm and leg lower, exhale as you extend" },
      { name: "Cat-Cow Stretch", category: "mobility", body_region: "spine", equipment: "none", load_type: "bodyweight", cueing: "Hands under shoulders, knees under hips, flow between positions" },
      { name: "Hip Flexor Stretch", category: "mobility", body_region: "lower_body", equipment: "none", load_type: "bodyweight", cueing: "Rear knee on ground, front knee at 90 degrees, push hips forward" },
      // Active Recovery exercises
      { name: "Walking", category: "cardio", body_region: "full_body", equipment: "none", load_type: "bodyweight", cueing: "Moderate pace, swing arms naturally, 10-15 minutes" },
      { name: "Foam Roll - Upper Back", category: "mobility", body_region: "upper_body", equipment: "foam_roller", load_type: "bodyweight", cueing: "Roll from mid-back to shoulders, pause on tight spots" },
      { name: "Foam Roll - Quads", category: "mobility", body_region: "lower_body", equipment: "foam_roller", load_type: "bodyweight", cueing: "Face down, roll from hip to knee, spend extra time on tight areas" },
      { name: "Gentle Yoga Flow", category: "mobility", body_region: "full_body", equipment: "none", load_type: "bodyweight", cueing: "Child pose, downward dog, cobra - flow slowly between positions" },
    ];

    // Insert exercise templates (upsert to avoid duplicates)
    const exerciseInserts = starterExercises.map((ex) => ({
      name: ex.name,
      category: ex.category,
      body_region: ex.body_region,
      equipment: ex.equipment,
      load_type: ex.load_type,
      cueing: ex.cueing,
    }));

    // Use upsert on name to avoid duplicates
    const { data: templates, error: templatesError } = await supabase
      .from("exercise_templates")
      .upsert(exerciseInserts, { onConflict: "name", ignoreDuplicates: true })
      .select("id, name");

    if (templatesError) {
      console.error("Error creating exercise templates:", templatesError);
      // Don't fail the whole thing - sessions still exist, just without exercises
    }

    // Get all template IDs (including any that already existed)
    const { data: allTemplates } = await supabase
      .from("exercise_templates")
      .select("id, name")
      .in("name", starterExercises.map((e) => e.name));

    if (allTemplates && sessions) {
      // Map exercise names to template IDs
      const templateMap = new Map(allTemplates.map((t) => [t.name, t.id]));

      // Session exercises configuration
      // target_reps is integer in DB, prescribed_reps is text for iOS compatibility
      const sessionExercisesConfig: Record<string, { exercises: string[]; sets: number; reps: number; repsText: string; notes: string }[]> = {
        "Full Body Basics": [
          { exercises: ["Bodyweight Squat"], sets: 3, reps: 12, repsText: "10-12", notes: "Focus on depth and control" },
          { exercises: ["Push-up (or Modified)"], sets: 3, reps: 10, repsText: "8-10", notes: "Modify on knees if needed" },
          { exercises: ["Glute Bridge"], sets: 3, reps: 15, repsText: "12-15", notes: "Squeeze at the top for 2 seconds" },
          { exercises: ["Bird Dog"], sets: 2, reps: 8, repsText: "8 each side", notes: "Slow and controlled" },
        ],
        "Core & Mobility": [
          { exercises: ["Plank Hold"], sets: 3, reps: 30, repsText: "20-30 sec", notes: "Keep breathing, don't hold breath" },
          { exercises: ["Dead Bug"], sets: 3, reps: 8, repsText: "8 each side", notes: "Press lower back into floor" },
          { exercises: ["Cat-Cow Stretch"], sets: 2, reps: 10, repsText: "10 cycles", notes: "Move slowly, breathe deeply" },
          { exercises: ["Hip Flexor Stretch"], sets: 2, reps: 30, repsText: "30 sec each", notes: "Gentle stretch, no bouncing" },
        ],
        "Active Recovery": [
          { exercises: ["Walking"], sets: 1, reps: 15, repsText: "10-15 min", notes: "Easy pace, enjoy the movement" },
          { exercises: ["Foam Roll - Upper Back"], sets: 1, reps: 2, repsText: "2 min", notes: "Roll slowly, pause on tight spots" },
          { exercises: ["Foam Roll - Quads"], sets: 1, reps: 2, repsText: "2 min each", notes: "Control the pressure" },
          { exercises: ["Gentle Yoga Flow"], sets: 1, reps: 5, repsText: "5 min", notes: "Flow at your own pace" },
        ],
      };

      // Create session_exercises for each session
      // Include both target_* (for schema) and prescribed_* (for iOS app compatibility)
      const sessionExercisesToInsert: Array<{
        session_id: string;
        exercise_template_id: string;
        sequence: number;
        order_index: number;
        block_number: number;
        block_label: string;
        target_sets: number;
        target_reps: number;
        prescribed_sets: number;
        prescribed_reps: string;
        rest_period_seconds: number;
        notes: string;
      }> = [];

      for (const session of sessions) {
        const config = sessionExercisesConfig[session.name];
        if (config) {
          config.forEach((exerciseConfig, index) => {
            const exerciseName = exerciseConfig.exercises[0];
            const templateId = templateMap.get(exerciseName);
            if (templateId) {
              sessionExercisesToInsert.push({
                session_id: session.id,
                exercise_template_id: templateId,
                sequence: index + 1,
                order_index: index + 1,
                block_number: 1,
                block_label: "Main",
                target_sets: exerciseConfig.sets,
                target_reps: exerciseConfig.reps,
                prescribed_sets: exerciseConfig.sets,
                prescribed_reps: exerciseConfig.repsText,
                rest_period_seconds: 60, // Default rest period
                notes: exerciseConfig.notes,
              });
            }
          });
        }
      }

      if (sessionExercisesToInsert.length > 0) {
        const { error: sessionExercisesError } = await supabase
          .from("session_exercises")
          .insert(sessionExercisesToInsert);

        if (sessionExercisesError) {
          console.error("Error creating session exercises:", sessionExercisesError);
          // Don't fail - sessions exist, just exercises might be missing
        }
      }
    }

    console.log(`Successfully created starter program ${program.id} for patient ${patientId}`);
    return { success: true, programId: program.id };
  } catch (err) {
    console.error("Unexpected error creating starter program:", err);
    return { success: false, error: String(err) };
  }
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Validate JWT authentication
    const authResult = await requireAuth(req)
    if (authResult instanceof Response) return authResult
    const authUser = authResult as AuthUser

    // Service role key to bypass RLS (new user has no policies yet)
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, serviceRoleKey);

    const { userId, email, fullName, authProvider }: RegisterRequest = await req.json();

    if (!email || !fullName) {
      return new Response(
        JSON.stringify({ error: "Missing required fields: email, fullName" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Use the authenticated user's ID from the JWT (more secure than trusting body)
    // This ensures users can only create patient records for themselves
    const actualUserId = authUser.user_id;

    // Log if there's a mismatch for debugging (but don't fail)
    if (userId && userId !== actualUserId) {
      console.warn(`userId mismatch: body=${userId}, jwt=${actualUserId} - using JWT value`);
    }

    // Parse name
    const nameParts = fullName.trim().split(" ");
    const firstName = nameParts[0] || "Patient";
    const lastName = nameParts.slice(1).join(" ") || "";

    // Check if patient already exists for this auth user
    const { data: existing } = await supabase
      .from("patients")
      .select("id")
      .eq("user_id", actualUserId)
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
        user_id: actualUserId,
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

    // Create starter program for the new patient (non-blocking)
    // We don't fail registration if program creation fails
    let starterProgramResult: { success: boolean; programId?: string; error?: string } = { success: false };
    try {
      starterProgramResult = await createStarterProgram(supabase, patient.id);
      if (!starterProgramResult.success) {
        console.warn(`Failed to create starter program for patient ${patient.id}: ${starterProgramResult.error}`);
      }
    } catch (programErr) {
      console.warn(`Exception creating starter program for patient ${patient.id}:`, programErr);
    }

    return new Response(
      JSON.stringify({
        patientId: patient.id,
        message: "Patient registered successfully",
        authProvider,
        starterProgram: starterProgramResult.success
          ? { created: true, programId: starterProgramResult.programId }
          : { created: false, error: starterProgramResult.error },
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
