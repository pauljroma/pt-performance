// ============================================================================
// AI SOAP Plan Suggestions Edge Function
// Generates AI-powered treatment plan suggestions for SOAP notes
// ============================================================================
// Date: 2026-02-09
// ============================================================================

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// ============================================================================
// TYPE DEFINITIONS
// ============================================================================

interface SOAPPlanSuggestionRequest {
  subjective: string
  objective: string
  assessment: string
  patient_id?: string
  diagnosis_code?: string
  therapist_id?: string
}

type PlanSuggestionCategory =
  | 'goals'
  | 'interventions'
  | 'education'
  | 'frequency'
  | 'precautions'
  | 'follow_up'
  | 'referral'
  | 'home_program'

type PlanSuggestionPriority = 'high' | 'medium' | 'low'

interface PlanSuggestion {
  id: string
  category: PlanSuggestionCategory
  content: string
  rationale: string
  priority: PlanSuggestionPriority
}

interface SOAPPlanSuggestionResponse {
  success: boolean
  suggestions: PlanSuggestion[]
  tokens_used: number
}

interface ErrorResponse {
  success: false
  error: string
  code?: string
}

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

function isValidUUID(uuid: string): boolean {
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
  return uuidRegex.test(uuid)
}

function generateUUID(): string {
  return crypto.randomUUID()
}

// Simple in-memory rate limiter
const rateLimitMap = new Map<string, { count: number; resetTime: number }>()
const RATE_LIMIT_WINDOW_MS = 60 * 1000 // 1 minute
const RATE_LIMIT_MAX_REQUESTS = 10 // 10 requests per minute

function checkRateLimit(identifier: string): boolean {
  const now = Date.now()
  const record = rateLimitMap.get(identifier)

  if (!record || now > record.resetTime) {
    rateLimitMap.set(identifier, { count: 1, resetTime: now + RATE_LIMIT_WINDOW_MS })
    return true
  }

  if (record.count >= RATE_LIMIT_MAX_REQUESTS) {
    return false
  }

  record.count++
  return true
}

// ============================================================================
// CLINICAL PROMPT BUILDER
// ============================================================================

function buildClinicalPrompt(request: SOAPPlanSuggestionRequest): string {
  const { subjective, objective, assessment, diagnosis_code } = request

  return `You are an expert physical therapy clinical documentation assistant. Your task is to generate evidence-based treatment plan suggestions for a SOAP note based on the provided Subjective, Objective, and Assessment information.

SOAP NOTE CONTENT:

SUBJECTIVE (Patient-reported information):
${subjective || 'Not provided'}

OBJECTIVE (Clinical measurements and findings):
${objective || 'Not provided'}

ASSESSMENT (Clinical impression):
${assessment || 'Not provided'}

${diagnosis_code ? `ICD-10 DIAGNOSIS CODE: ${diagnosis_code}` : ''}

TASK: Generate comprehensive treatment plan suggestions across these categories:

1. GOALS (Short-term and long-term functional goals - SMART format preferred)
2. INTERVENTIONS (Specific therapeutic exercises, manual therapy, modalities)
3. EDUCATION (Patient education topics and self-management strategies)
4. FREQUENCY (Recommended treatment frequency and duration)
5. PRECAUTIONS (Safety considerations and contraindications)
6. FOLLOW_UP (Reassessment criteria and discharge planning)
7. REFERRAL (If additional specialists or services are indicated)
8. HOME_PROGRAM (Home exercise program components)

CLINICAL GUIDELINES:
- Suggestions must be evidence-based and clinically appropriate
- Goals should be measurable and time-bound
- Interventions should target identified impairments
- Consider patient-reported functional limitations
- Include safety precautions when relevant
- Frequency recommendations should align with diagnosis severity
- Home programs should be realistic and achievable

PRIORITY LEVELS:
- high: Critical for patient safety or primary treatment goals
- medium: Important for comprehensive care
- low: Supplementary or optional recommendations

Respond with valid JSON ONLY in this exact format:
{
  "suggestions": [
    {
      "category": "goals|interventions|education|frequency|precautions|follow_up|referral|home_program",
      "content": "The specific plan item text (clinical and professional)",
      "rationale": "Brief clinical reasoning for this recommendation",
      "priority": "high|medium|low"
    }
  ]
}

Generate 6-10 diverse, clinically relevant suggestions covering multiple categories. Prioritize suggestions based on the clinical presentation.`
}

// ============================================================================
// AI API CALL
// ============================================================================

async function callAnthropicAPI(prompt: string): Promise<{ content: string; tokens: number }> {
  const anthropicApiKey = Deno.env.get('ANTHROPIC_API_KEY')

  if (!anthropicApiKey) {
    throw new Error('ANTHROPIC_API_KEY environment variable not configured')
  }

  console.log('[ai-soap-plan-suggestions] Calling Anthropic Claude API...')

  const response = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'x-api-key': anthropicApiKey,
      'anthropic-version': '2023-06-01',
    },
    body: JSON.stringify({
      model: 'claude-sonnet-4-20250514',
      max_tokens: 2048,
      temperature: 0.4,
      messages: [
        {
          role: 'user',
          content: prompt
        }
      ],
    }),
  })

  if (!response.ok) {
    const errorText = await response.text()
    console.error('[ai-soap-plan-suggestions] Anthropic API error:', response.status, errorText)

    if (response.status === 429) {
      throw new Error('AI service rate limit exceeded. Please try again in a moment.')
    }
    if (response.status === 401 || response.status === 403) {
      throw new Error('AI service authentication failed.')
    }

    throw new Error(`AI service error (${response.status}): ${errorText.substring(0, 200)}`)
  }

  const completion = await response.json()
  const responseText = completion.content?.[0]?.text

  if (!responseText) {
    throw new Error('No text content in AI response')
  }

  // Calculate tokens (Anthropic returns usage info)
  const inputTokens = completion.usage?.input_tokens || 0
  const outputTokens = completion.usage?.output_tokens || 0
  const totalTokens = inputTokens + outputTokens

  console.log(`[ai-soap-plan-suggestions] Received response (${totalTokens} tokens)`)

  return { content: responseText, tokens: totalTokens }
}

// Fallback to OpenAI if Anthropic fails or is not configured
async function callOpenAIAPI(prompt: string): Promise<{ content: string; tokens: number }> {
  const openaiApiKey = Deno.env.get('OPENAI_API_KEY')

  if (!openaiApiKey) {
    throw new Error('OPENAI_API_KEY environment variable not configured')
  }

  console.log('[ai-soap-plan-suggestions] Calling OpenAI API (fallback)...')

  const response = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${openaiApiKey}`,
    },
    body: JSON.stringify({
      model: 'gpt-4-turbo-preview',
      max_tokens: 2048,
      temperature: 0.4,
      messages: [
        {
          role: 'system',
          content: 'You are an expert physical therapy clinical documentation assistant. Always respond with valid JSON only.'
        },
        {
          role: 'user',
          content: prompt
        }
      ],
    }),
  })

  if (!response.ok) {
    const errorText = await response.text()
    console.error('[ai-soap-plan-suggestions] OpenAI API error:', response.status, errorText)

    if (response.status === 429) {
      throw new Error('AI service rate limit exceeded. Please try again in a moment.')
    }

    throw new Error(`AI service error (${response.status}): ${errorText.substring(0, 200)}`)
  }

  const completion = await response.json()
  const responseText = completion.choices?.[0]?.message?.content

  if (!responseText) {
    throw new Error('No text content in AI response')
  }

  const totalTokens = completion.usage?.total_tokens || 0

  console.log(`[ai-soap-plan-suggestions] Received OpenAI response (${totalTokens} tokens)`)

  return { content: responseText, tokens: totalTokens }
}

// ============================================================================
// RESPONSE PARSING AND VALIDATION
// ============================================================================

const VALID_CATEGORIES: PlanSuggestionCategory[] = [
  'goals',
  'interventions',
  'education',
  'frequency',
  'precautions',
  'follow_up',
  'referral',
  'home_program'
]

const VALID_PRIORITIES: PlanSuggestionPriority[] = ['high', 'medium', 'low']

function parseAndValidateSuggestions(responseText: string): PlanSuggestion[] {
  // Extract JSON from response (handle markdown code blocks)
  let jsonContent: string
  const jsonMatch = responseText.match(/\{[\s\S]*\}/)

  if (jsonMatch) {
    jsonContent = jsonMatch[0]
  } else {
    throw new Error('No valid JSON found in AI response')
  }

  let parsed: { suggestions: unknown[] }
  try {
    parsed = JSON.parse(jsonContent)
  } catch (parseError) {
    console.error('[ai-soap-plan-suggestions] JSON parse error:', parseError)
    throw new Error('Failed to parse AI response as JSON')
  }

  if (!parsed.suggestions || !Array.isArray(parsed.suggestions)) {
    throw new Error('AI response missing suggestions array')
  }

  // Validate and transform each suggestion
  const validatedSuggestions: PlanSuggestion[] = []

  for (const suggestion of parsed.suggestions) {
    if (typeof suggestion !== 'object' || suggestion === null) {
      console.warn('[ai-soap-plan-suggestions] Skipping invalid suggestion:', suggestion)
      continue
    }

    const s = suggestion as Record<string, unknown>

    // Validate category
    const category = String(s.category || '').toLowerCase() as PlanSuggestionCategory
    if (!VALID_CATEGORIES.includes(category)) {
      console.warn(`[ai-soap-plan-suggestions] Invalid category "${s.category}", skipping`)
      continue
    }

    // Validate content
    const content = String(s.content || '').trim()
    if (!content) {
      console.warn('[ai-soap-plan-suggestions] Empty content, skipping')
      continue
    }

    // Validate priority (default to medium if invalid)
    let priority = String(s.priority || 'medium').toLowerCase() as PlanSuggestionPriority
    if (!VALID_PRIORITIES.includes(priority)) {
      priority = 'medium'
    }

    // Rationale is optional
    const rationale = String(s.rationale || '').trim()

    validatedSuggestions.push({
      id: generateUUID(),
      category,
      content,
      rationale,
      priority
    })
  }

  if (validatedSuggestions.length === 0) {
    throw new Error('No valid suggestions generated')
  }

  // Sort by priority (high first, then medium, then low)
  validatedSuggestions.sort((a, b) => {
    const priorityOrder = { high: 0, medium: 1, low: 2 }
    return priorityOrder[a.priority] - priorityOrder[b.priority]
  })

  return validatedSuggestions
}

// ============================================================================
// MAIN HANDLER
// ============================================================================

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  // Only allow POST requests
  if (req.method !== 'POST') {
    return new Response(
      JSON.stringify({ success: false, error: 'Method not allowed' } as ErrorResponse),
      { status: 405, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }

  try {
    // Parse request body
    const requestBody = await req.json() as SOAPPlanSuggestionRequest
    const { subjective, objective, assessment, patient_id, diagnosis_code, therapist_id } = requestBody

    console.log('[ai-soap-plan-suggestions] Received request:', {
      hasSubjective: !!subjective,
      hasObjective: !!objective,
      hasAssessment: !!assessment,
      hasDiagnosisCode: !!diagnosis_code,
      hasPatientId: !!patient_id,
      hasTherapistId: !!therapist_id
    })

    // Validate that at least one section has content
    const hasSubjective = subjective && subjective.trim().length > 0
    const hasObjective = objective && objective.trim().length > 0
    const hasAssessment = assessment && assessment.trim().length > 0

    if (!hasSubjective && !hasObjective && !hasAssessment) {
      return new Response(
        JSON.stringify({
          success: false,
          error: 'At least one section (subjective, objective, or assessment) must contain content',
          code: 'ERR_INSUFFICIENT_INPUT'
        } as ErrorResponse),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Validate optional UUID fields
    if (patient_id && !isValidUUID(patient_id)) {
      return new Response(
        JSON.stringify({
          success: false,
          error: 'Invalid patient_id format',
          code: 'ERR_INVALID_UUID'
        } as ErrorResponse),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    if (therapist_id && !isValidUUID(therapist_id)) {
      return new Response(
        JSON.stringify({
          success: false,
          error: 'Invalid therapist_id format',
          code: 'ERR_INVALID_UUID'
        } as ErrorResponse),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Rate limiting (use therapist_id or patient_id or IP as identifier)
    const rateLimitId = therapist_id || patient_id || req.headers.get('x-forwarded-for') || 'anonymous'
    if (!checkRateLimit(rateLimitId)) {
      return new Response(
        JSON.stringify({
          success: false,
          error: 'Rate limit exceeded. Please wait before making more requests.',
          code: 'ERR_RATE_LIMIT'
        } as ErrorResponse),
        { status: 429, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Build the clinical prompt
    const prompt = buildClinicalPrompt(requestBody)

    // Call AI API (try Anthropic first, fallback to OpenAI)
    let aiResponse: { content: string; tokens: number }

    try {
      aiResponse = await callAnthropicAPI(prompt)
    } catch (anthropicError) {
      console.warn('[ai-soap-plan-suggestions] Anthropic failed, trying OpenAI:', anthropicError)

      try {
        aiResponse = await callOpenAIAPI(prompt)
      } catch (openaiError) {
        console.error('[ai-soap-plan-suggestions] Both AI providers failed')
        throw new Error('AI service temporarily unavailable. Please try again later.')
      }
    }

    // Parse and validate the AI response
    const suggestions = parseAndValidateSuggestions(aiResponse.content)

    console.log(`[ai-soap-plan-suggestions] Successfully generated ${suggestions.length} suggestions`)

    // Build success response
    const response: SOAPPlanSuggestionResponse = {
      success: true,
      suggestions,
      tokens_used: aiResponse.tokens
    }

    return new Response(
      JSON.stringify(response),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('[ai-soap-plan-suggestions] Error:', error)

    const errorMessage = error instanceof Error ? error.message : 'An unexpected error occurred'
    const isRateLimit = errorMessage.toLowerCase().includes('rate limit')

    return new Response(
      JSON.stringify({
        success: false,
        error: errorMessage,
        code: isRateLimit ? 'ERR_RATE_LIMIT' : 'ERR_INTERNAL'
      } as ErrorResponse),
      {
        status: isRateLimit ? 429 : 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  }
})
