// ============================================================================
// Parse Lab PDF Edge Function
// Health Intelligence Platform - Lab Result Extraction
// ============================================================================
// Accepts a PDF document as base64, uses Claude Vision to extract biomarker
// data, and returns structured JSON with test results.
//
// Date: 2026-02-03
// Ticket: ACP-1202
// ============================================================================

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// ============================================================================
// TYPE DEFINITIONS
// ============================================================================

interface ParseLabPDFRequest {
  pdf_base64?: string  // Deprecated: PDFs not directly supported
  images_base64?: string[]  // Array of page images as base64 PNG/JPEG
  filename?: string
}

interface ParsedBiomarker {
  name: string
  value: number
  unit: string
  reference_range?: string
  reference_low?: number | null
  reference_high?: number | null
  flag?: 'normal' | 'low' | 'high' | 'critical' | null
  category?: string
}

interface ParseLabPDFResponse {
  success: boolean
  provider?: 'quest' | 'labcorp' | 'unknown' | string
  test_date?: string
  patient_name?: string
  ordering_physician?: string
  biomarkers: ParsedBiomarker[]
  raw_text_preview?: string
  confidence: 'high' | 'medium' | 'low'
  parsing_notes?: string[]
  error?: string
}

// ============================================================================
// KNOWN LAB PROVIDERS DETECTION PATTERNS
// ============================================================================

const LAB_PROVIDER_PATTERNS = {
  quest: [
    'quest diagnostics',
    'questdiagnostics',
    'quest.com',
    'www.questdiagnostics.com',
  ],
  labcorp: [
    'labcorp',
    'laboratory corporation of america',
    'labcorp.com',
    'www.labcorp.com',
  ],
}

function detectLabProvider(text: string): 'quest' | 'labcorp' | 'unknown' {
  const lowerText = text.toLowerCase()

  for (const pattern of LAB_PROVIDER_PATTERNS.quest) {
    if (lowerText.includes(pattern)) return 'quest'
  }

  for (const pattern of LAB_PROVIDER_PATTERNS.labcorp) {
    if (lowerText.includes(pattern)) return 'labcorp'
  }

  return 'unknown'
}

// ============================================================================
// BIOMARKER NORMALIZATION
// ============================================================================

// Standard biomarker type mappings for database consistency
const BIOMARKER_TYPE_MAPPINGS: Record<string, string> = {
  // Complete Blood Count
  'wbc': 'wbc',
  'white blood cell': 'wbc',
  'white blood cell count': 'wbc',
  'rbc': 'rbc',
  'red blood cell': 'rbc',
  'red blood cell count': 'rbc',
  'hemoglobin': 'hemoglobin',
  'hgb': 'hemoglobin',
  'hematocrit': 'hematocrit',
  'hct': 'hematocrit',
  'platelet count': 'platelets',
  'platelets': 'platelets',
  'plt': 'platelets',
  'mcv': 'mcv',
  'mean corpuscular volume': 'mcv',
  'mch': 'mch',
  'mean corpuscular hemoglobin': 'mch',
  'mchc': 'mchc',
  'rdw': 'rdw',
  'red cell distribution width': 'rdw',

  // Metabolic Panel
  'glucose': 'glucose',
  'fasting glucose': 'glucose_fasting',
  'blood glucose': 'glucose',
  'bun': 'bun',
  'blood urea nitrogen': 'bun',
  'creatinine': 'creatinine',
  'egfr': 'egfr',
  'estimated gfr': 'egfr',
  'glomerular filtration rate': 'egfr',
  'sodium': 'sodium',
  'na': 'sodium',
  'potassium': 'potassium',
  'k': 'potassium',
  'chloride': 'chloride',
  'cl': 'chloride',
  'co2': 'co2',
  'carbon dioxide': 'co2',
  'calcium': 'calcium',
  'ca': 'calcium',

  // Lipid Panel
  'total cholesterol': 'cholesterol_total',
  'cholesterol': 'cholesterol_total',
  'cholesterol, total': 'cholesterol_total',
  'hdl': 'hdl',
  'hdl cholesterol': 'hdl',
  'hdl-c': 'hdl',
  'ldl': 'ldl',
  'ldl cholesterol': 'ldl',
  'ldl-c': 'ldl',
  'ldl calculated': 'ldl',
  'triglycerides': 'triglycerides',
  'trig': 'triglycerides',
  'vldl': 'vldl',
  'vldl cholesterol': 'vldl',

  // Liver Panel
  'alt': 'alt',
  'alanine aminotransferase': 'alt',
  'sgpt': 'alt',
  'ast': 'ast',
  'aspartate aminotransferase': 'ast',
  'sgot': 'ast',
  'alp': 'alp',
  'alkaline phosphatase': 'alp',
  'bilirubin': 'bilirubin_total',
  'bilirubin, total': 'bilirubin_total',
  'total bilirubin': 'bilirubin_total',
  'direct bilirubin': 'bilirubin_direct',
  'albumin': 'albumin',
  'total protein': 'protein_total',
  'protein, total': 'protein_total',
  'globulin': 'globulin',
  'a/g ratio': 'ag_ratio',
  'ggt': 'ggt',
  'gamma-glutamyl transferase': 'ggt',

  // Thyroid Panel
  'tsh': 'tsh',
  'thyroid stimulating hormone': 'tsh',
  'free t4': 'free_t4',
  't4, free': 'free_t4',
  'ft4': 'free_t4',
  'free t3': 'free_t3',
  't3, free': 'free_t3',
  'ft3': 'free_t3',
  't3': 't3_total',
  't4': 't4_total',

  // Hormones
  'testosterone': 'testosterone_total',
  'testosterone, total': 'testosterone_total',
  'total testosterone': 'testosterone_total',
  'free testosterone': 'testosterone_free',
  'testosterone, free': 'testosterone_free',
  'estradiol': 'estradiol',
  'e2': 'estradiol',
  'progesterone': 'progesterone',
  'dhea-s': 'dhea_s',
  'dhea sulfate': 'dhea_s',
  'cortisol': 'cortisol',
  'cortisol, am': 'cortisol_am',
  'shbg': 'shbg',
  'sex hormone binding globulin': 'shbg',
  'lh': 'lh',
  'luteinizing hormone': 'lh',
  'fsh': 'fsh',
  'follicle stimulating hormone': 'fsh',
  'prolactin': 'prolactin',
  'igf-1': 'igf1',
  'insulin-like growth factor 1': 'igf1',

  // Vitamins & Minerals
  'vitamin d': 'vitamin_d',
  'vitamin d, 25-hydroxy': 'vitamin_d',
  '25-hydroxy vitamin d': 'vitamin_d',
  'vitamin d 25-oh': 'vitamin_d',
  'vitamin b12': 'vitamin_b12',
  'b12': 'vitamin_b12',
  'cobalamin': 'vitamin_b12',
  'folate': 'folate',
  'folic acid': 'folate',
  'iron': 'iron',
  'serum iron': 'iron',
  'ferritin': 'ferritin',
  'tibc': 'tibc',
  'total iron binding capacity': 'tibc',
  'iron saturation': 'iron_saturation',
  'transferrin saturation': 'iron_saturation',
  'magnesium': 'magnesium',
  'mg': 'magnesium',
  'zinc': 'zinc',
  'zn': 'zinc',

  // Inflammation Markers
  'crp': 'crp',
  'c-reactive protein': 'crp',
  'hs-crp': 'hscrp',
  'high sensitivity crp': 'hscrp',
  'esr': 'esr',
  'sed rate': 'esr',
  'erythrocyte sedimentation rate': 'esr',
  'homocysteine': 'homocysteine',

  // Diabetes Markers
  'hba1c': 'hba1c',
  'hemoglobin a1c': 'hba1c',
  'a1c': 'hba1c',
  'glycated hemoglobin': 'hba1c',
  'insulin': 'insulin',
  'fasting insulin': 'insulin_fasting',

  // Other Common
  'uric acid': 'uric_acid',
  'psa': 'psa',
  'prostate specific antigen': 'psa',
  'vitamin a': 'vitamin_a',
  'vitamin e': 'vitamin_e',
  'vitamin c': 'vitamin_c',
  'omega-3 index': 'omega3_index',
  'apolipoprotein b': 'apob',
  'apo b': 'apob',
  'lipoprotein(a)': 'lpa',
  'lp(a)': 'lpa',
}

function normalizeBiomarkerType(name: string): string {
  const lowerName = name.toLowerCase().trim()
  return BIOMARKER_TYPE_MAPPINGS[lowerName] || lowerName.replace(/[^a-z0-9]/g, '_')
}

// ============================================================================
// MAIN HANDLER
// ============================================================================

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Log request details for debugging
    console.log(`[parse-lab-pdf] Request method: ${req.method}`)
    console.log(`[parse-lab-pdf] Content-Type: ${req.headers.get('content-type')}`)
    console.log(`[parse-lab-pdf] Content-Length: ${req.headers.get('content-length')}`)

    let requestBody: ParseLabPDFRequest
    try {
      requestBody = await req.json() as ParseLabPDFRequest
      console.log(`[parse-lab-pdf] Body parsed successfully, has pdf_base64: ${!!requestBody.pdf_base64}`)
      if (requestBody.pdf_base64) {
        console.log(`[parse-lab-pdf] pdf_base64 length: ${requestBody.pdf_base64.length}`)
      }
    } catch (parseError) {
      console.error(`[parse-lab-pdf] JSON parse error:`, parseError)
      return new Response(
        JSON.stringify({
          success: false,
          error: `Failed to parse request body: ${parseError instanceof Error ? parseError.message : 'Unknown error'}`,
          biomarkers: [],
          confidence: 'low'
        } as ParseLabPDFResponse),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const { pdf_base64, images_base64, filename } = requestBody

    // Validate required fields - need either images_base64 (preferred) or pdf_base64
    if (!images_base64 && !pdf_base64) {
      return new Response(
        JSON.stringify({
          success: false,
          error: 'images_base64 array is required. Please convert PDF pages to images before uploading.',
          biomarkers: [],
          confidence: 'low'
        } as ParseLabPDFResponse),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // If pdf_base64 is provided but not images, return error with instructions
    if (pdf_base64 && !images_base64) {
      return new Response(
        JSON.stringify({
          success: false,
          error: 'PDF format not supported directly. Please convert PDF pages to images (PNG/JPEG) and send as images_base64 array.',
          biomarkers: [],
          confidence: 'low'
        } as ParseLabPDFResponse),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Validate images array
    if (!images_base64 || images_base64.length === 0) {
      return new Response(
        JSON.stringify({
          success: false,
          error: 'images_base64 array cannot be empty',
          biomarkers: [],
          confidence: 'low'
        } as ParseLabPDFResponse),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Limit number of pages
    if (images_base64.length > 20) {
      return new Response(
        JSON.stringify({
          success: false,
          error: 'Too many pages. Maximum 20 pages supported.',
          biomarkers: [],
          confidence: 'low'
        } as ParseLabPDFResponse),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    console.log(`[parse-lab-pdf] Processing ${images_base64.length} page(s)${filename ? ` from: ${filename}` : ''}`)

    // Get Anthropic API key
    const anthropicApiKey = Deno.env.get('ANTHROPIC_API_KEY')
    if (!anthropicApiKey) {
      throw new Error('ANTHROPIC_API_KEY environment variable not set')
    }

    // ========================================================================
    // CALL CLAUDE VISION API
    // ========================================================================

    const systemPrompt = `You are an expert medical lab result parser. Your task is to extract biomarker data from lab result PDFs with high accuracy.

CRITICAL RULES:
1. Extract ALL test results visible in the document
2. Parse exact numerical values - do not round or estimate
3. Include the unit of measurement for each test
4. Extract reference ranges when provided
5. Identify flags (H = high, L = low, A = abnormal, C = critical)
6. Detect the lab provider (Quest Diagnostics, LabCorp, etc.)
7. Extract the test/collection date if visible
8. Extract patient name if visible (for verification purposes)

OUTPUT FORMAT:
Return ONLY valid JSON with this exact structure:
{
  "provider": "quest" | "labcorp" | "unknown" | "other provider name",
  "test_date": "YYYY-MM-DD" or null if not found,
  "patient_name": "Name" or null if not found,
  "ordering_physician": "Dr. Name" or null if not found,
  "biomarkers": [
    {
      "name": "Test Name (exactly as shown)",
      "value": 123.4,
      "unit": "mg/dL",
      "reference_range": "70-100",
      "reference_low": 70,
      "reference_high": 100,
      "flag": "normal" | "low" | "high" | "critical" | null,
      "category": "Lipid Panel" | "CBC" | "Metabolic" | etc.
    }
  ],
  "confidence": "high" | "medium" | "low",
  "parsing_notes": ["Any issues or uncertainties noted during parsing"]
}

CONFIDENCE LEVELS:
- high: All values clearly visible and readable
- medium: Some values unclear or partially obscured
- low: Significant portions unreadable or uncertain

IMPORTANT:
- If a value cannot be parsed as a number, skip that biomarker
- Reference ranges like "<100" should set reference_high to 100 and reference_low to null
- Reference ranges like ">40" should set reference_low to 40 and reference_high to null
- Flags marked with "H" or "HIGH" = "high", "L" or "LOW" = "low", "C" or "CRITICAL" = "critical"
- No flag or within range = "normal"`

    const userPrompt = images_base64.length === 1
      ? `Please analyze this lab result page and extract all biomarker data. Return the structured JSON with all test results, reference ranges, and flags.`
      : `Please analyze these ${images_base64.length} lab result pages and extract all biomarker data from ALL pages. Combine results from all pages into a single response. Return the structured JSON with all test results, reference ranges, and flags.`

    console.log('[parse-lab-pdf] Calling Claude Vision API...')

    // Build content array with text prompt and all images
    const contentArray: Array<{ type: string; text?: string; source?: { type: string; media_type: string; data: string } }> = [
      {
        type: 'text',
        text: `${systemPrompt}\n\n${userPrompt}`
      }
    ]

    // Add each page image
    for (let i = 0; i < images_base64.length; i++) {
      const imageData = images_base64[i]
      // Detect media type from base64 header or default to PNG
      let mediaType = 'image/png'
      if (imageData.startsWith('/9j/')) {
        mediaType = 'image/jpeg'
      } else if (imageData.startsWith('R0lGOD')) {
        mediaType = 'image/gif'
      } else if (imageData.startsWith('UklGR')) {
        mediaType = 'image/webp'
      }

      contentArray.push({
        type: 'image',
        source: {
          type: 'base64',
          media_type: mediaType,
          data: imageData,
        },
      })
      console.log(`[parse-lab-pdf] Added page ${i + 1}, size: ${imageData.length} chars, type: ${mediaType}`)
    }

    const anthropicResponse = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': anthropicApiKey,
        'anthropic-version': '2023-06-01',
      },
      body: JSON.stringify({
        model: 'claude-sonnet-4-20250514',
        max_tokens: 8192, // Increased for multi-page results
        messages: [
          {
            role: 'user',
            content: contentArray
          }
        ],
        temperature: 0.1, // Low temperature for accurate extraction
      }),
    })

    if (!anthropicResponse.ok) {
      const error = await anthropicResponse.text()
      console.error('[parse-lab-pdf] Anthropic API error:', anthropicResponse.status, error)

      // Check for specific error types
      if (anthropicResponse.status === 400 && error.includes('image')) {
        return new Response(
          JSON.stringify({
            success: false,
            error: 'PDF format not supported. Please try converting to images or ensure the PDF is not encrypted.',
            biomarkers: [],
            confidence: 'low'
          } as ParseLabPDFResponse),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }

      throw new Error(`Anthropic API error (${anthropicResponse.status}): ${error.substring(0, 200)}`)
    }

    const completion = await anthropicResponse.json()
    const responseText = completion.content?.[0]?.text

    if (!responseText) {
      throw new Error('No text content in Anthropic response')
    }

    console.log('[parse-lab-pdf] Received response from Claude')

    // Parse the JSON response
    let parsedResponse: any
    try {
      // Extract JSON from the response (handle markdown code blocks)
      const jsonMatch = responseText.match(/\{[\s\S]*\}/)
      parsedResponse = jsonMatch ? JSON.parse(jsonMatch[0]) : JSON.parse(responseText)
    } catch (parseError) {
      console.error('[parse-lab-pdf] Failed to parse AI response:', responseText.substring(0, 500))
      throw new Error('Failed to parse AI response as JSON')
    }

    // ========================================================================
    // VALIDATE AND NORMALIZE RESPONSE
    // ========================================================================

    const biomarkers: ParsedBiomarker[] = []
    const parsingNotes: string[] = parsedResponse.parsing_notes || []

    if (Array.isArray(parsedResponse.biomarkers)) {
      for (const bm of parsedResponse.biomarkers) {
        // Validate required fields
        if (!bm.name || typeof bm.value !== 'number') {
          parsingNotes.push(`Skipped biomarker with invalid data: ${JSON.stringify(bm)}`)
          continue
        }

        // Normalize the biomarker
        const normalizedBiomarker: ParsedBiomarker = {
          name: bm.name,
          value: bm.value,
          unit: bm.unit || '',
          reference_range: bm.reference_range || null,
          reference_low: typeof bm.reference_low === 'number' ? bm.reference_low : null,
          reference_high: typeof bm.reference_high === 'number' ? bm.reference_high : null,
          flag: ['normal', 'low', 'high', 'critical'].includes(bm.flag) ? bm.flag : null,
          category: bm.category || 'Other'
        }

        // Auto-detect flag if not provided
        if (!normalizedBiomarker.flag && normalizedBiomarker.reference_low !== null && normalizedBiomarker.reference_high !== null) {
          if (normalizedBiomarker.value < normalizedBiomarker.reference_low) {
            normalizedBiomarker.flag = 'low'
          } else if (normalizedBiomarker.value > normalizedBiomarker.reference_high) {
            normalizedBiomarker.flag = 'high'
          } else {
            normalizedBiomarker.flag = 'normal'
          }
        }

        biomarkers.push(normalizedBiomarker)
      }
    }

    // Validate test date format
    let testDate: string | undefined = undefined
    if (parsedResponse.test_date) {
      const dateMatch = parsedResponse.test_date.match(/\d{4}-\d{2}-\d{2}/)
      if (dateMatch) {
        testDate = dateMatch[0]
      } else {
        parsingNotes.push(`Could not parse test date: ${parsedResponse.test_date}`)
      }
    }

    // Determine confidence
    let confidence: 'high' | 'medium' | 'low' = parsedResponse.confidence || 'medium'
    if (biomarkers.length === 0) {
      confidence = 'low'
      parsingNotes.push('No biomarkers could be extracted from the document')
    } else if (biomarkers.length < 3) {
      confidence = confidence === 'high' ? 'medium' : confidence
    }

    // Build response
    const response: ParseLabPDFResponse = {
      success: biomarkers.length > 0,
      provider: parsedResponse.provider || 'unknown',
      test_date: testDate,
      patient_name: parsedResponse.patient_name || undefined,
      ordering_physician: parsedResponse.ordering_physician || undefined,
      biomarkers: biomarkers,
      confidence: confidence,
      parsing_notes: parsingNotes.length > 0 ? parsingNotes : undefined,
    }

    console.log(`[parse-lab-pdf] Successfully extracted ${biomarkers.length} biomarkers from ${response.provider} lab`)

    return new Response(
      JSON.stringify(response),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('[parse-lab-pdf] Error:', error)

    const errorMessage = error instanceof Error ? error.message : 'Internal server error'

    return new Response(
      JSON.stringify({
        success: false,
        error: errorMessage,
        biomarkers: [],
        confidence: 'low'
      } as ParseLabPDFResponse),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
