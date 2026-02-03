// ============================================================================
// Mock Anthropic Client for Testing
// Health Intelligence Platform - Edge Function Tests
// ============================================================================

export interface MockMessage {
  id: string;
  type: string;
  role: string;
  content: Array<{
    type: string;
    text: string;
  }>;
  model: string;
  stop_reason: string;
  stop_sequence: null;
  usage: {
    input_tokens: number;
    output_tokens: number;
  };
}

export interface MockAnthropicClient {
  messages: {
    create: (params: any) => Promise<MockMessage>;
  };
  _setMockResponse: (response: string | object) => void;
  _setMockError: (error: Error | null) => void;
  _getMockCallHistory: () => any[];
  _clearHistory: () => void;
}

export function createMockAnthropicClient(): MockAnthropicClient {
  let mockResponse: string | object = '{}';
  let mockError: Error | null = null;
  const callHistory: any[] = [];

  return {
    messages: {
      create: async (params: any): Promise<MockMessage> => {
        callHistory.push(params);

        if (mockError) {
          throw mockError;
        }

        const responseText = typeof mockResponse === 'string'
          ? mockResponse
          : JSON.stringify(mockResponse);

        return {
          id: 'msg_mock_' + crypto.randomUUID(),
          type: 'message',
          role: 'assistant',
          content: [
            {
              type: 'text',
              text: responseText
            }
          ],
          model: params.model || 'claude-sonnet-4-20250514',
          stop_reason: 'end_turn',
          stop_sequence: null,
          usage: {
            input_tokens: 100,
            output_tokens: 200
          }
        };
      }
    },
    _setMockResponse: (response: string | object) => {
      mockResponse = response;
    },
    _setMockError: (error: Error | null) => {
      mockError = error;
    },
    _getMockCallHistory: () => [...callHistory],
    _clearHistory: () => {
      callHistory.length = 0;
    }
  };
}

// Mock fetch response for direct API calls
export function createMockAnthropicFetch(mockResponse: string | object, status = 200) {
  return async (_url: string, _options: RequestInit): Promise<Response> => {
    if (status !== 200) {
      return new Response(JSON.stringify({ error: { message: 'API Error' } }), {
        status,
        headers: { 'Content-Type': 'application/json' }
      });
    }

    const responseText = typeof mockResponse === 'string'
      ? mockResponse
      : JSON.stringify(mockResponse);

    const responseBody = {
      id: 'msg_mock_' + crypto.randomUUID(),
      type: 'message',
      role: 'assistant',
      content: [
        {
          type: 'text',
          text: responseText
        }
      ],
      model: 'claude-sonnet-4-20250514',
      stop_reason: 'end_turn',
      stop_sequence: null,
      usage: {
        input_tokens: 100,
        output_tokens: 200
      }
    };

    return new Response(JSON.stringify(responseBody), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    });
  };
}

// Standard mock responses for different function types

export const MOCK_AI_COACH_RESPONSE = {
  response: "Based on your data, I can see you've been training consistently with 4 workouts in the past week. Your HRV has been trending upward, which suggests good recovery. I'd recommend focusing on maintaining your current training intensity while ensuring adequate sleep.",
  insights: [
    {
      category: "training",
      observation: "4 workouts completed in the last 7 days with good consistency",
      recommendation: "Maintain current training frequency, consider adding one recovery session",
      priority: "medium"
    },
    {
      category: "recovery",
      observation: "HRV trending upward indicates positive adaptation",
      recommendation: "Continue current recovery practices",
      priority: "low"
    }
  ],
  suggested_questions: [
    "How can I optimize my sleep for better recovery?",
    "Should I increase my training volume?",
    "What supplements might help with my goals?"
  ]
};

export const MOCK_LAB_ANALYSIS_RESPONSE = {
  analysis_text: "Your lab results show generally healthy values with a few areas to optimize. Vitamin D is slightly below optimal range at 32 ng/mL - consider increasing supplementation to 5000 IU daily. Your lipid panel looks excellent with LDL at 95 and HDL at 62.",
  biomarker_interpretations: {
    vitamin_d: "Slightly below optimal (target 40-60 ng/mL). Common in athletes with indoor training.",
    hdl: "Excellent level indicating good cardiovascular health",
    ldl: "Well within optimal range for athletic performance"
  },
  recommendations: [
    "Increase Vitamin D3 supplementation to 5000 IU daily with fat-containing meal",
    "Continue current exercise regimen for maintaining healthy lipid profile",
    "Consider adding omega-3 supplementation for further cardiovascular support"
  ],
  training_correlations: [
    {
      factor: "Training Volume",
      relationship: "Your consistent training positively impacts your lipid profile",
      recommendation: "Maintain current training load"
    }
  ],
  sleep_correlations: [
    {
      factor: "Sleep Duration",
      relationship: "Adequate sleep supports hormone optimization",
      recommendation: "Aim for 7-9 hours consistently"
    }
  ],
  priority_actions: [
    "Start Vitamin D3 5000 IU supplementation",
    "Retest Vitamin D in 8 weeks"
  ],
  concerns: []
};

export const MOCK_SUPPLEMENT_RESPONSE = {
  stack_summary: "Based on your goals of muscle building and recovery optimization, I recommend a foundational stack of Creatine, Vitamin D3, and Omega-3s. Given your sleep data showing an average of 6.5 hours, Magnesium L-Threonate would be a valuable addition for sleep quality.",
  recommendations: [
    {
      supplement_key: "creatine",
      priority: "essential",
      rationale: "Most researched performance supplement. Supports strength gains and cognitive function.",
      goal_alignment: ["muscle building", "performance"],
      dosage_adjustment: null,
      timing_notes: "5g daily, timing doesn't matter",
      warnings: []
    },
    {
      supplement_key: "vitamin_d3",
      priority: "essential",
      rationale: "Your lab showed 32 ng/mL - below optimal. Essential for immune function and hormone health.",
      goal_alignment: ["general health", "recovery"],
      dosage_adjustment: "5000 IU (standard dose)",
      timing_notes: "Morning with breakfast containing fat",
      warnings: []
    },
    {
      supplement_key: "magnesium",
      priority: "recommended",
      rationale: "Sleep hours averaging 6.5 - magnesium L-threonate can improve sleep quality and duration.",
      goal_alignment: ["sleep", "recovery"],
      dosage_adjustment: null,
      timing_notes: "30-60 minutes before bed",
      warnings: []
    },
    {
      supplement_key: "omega3",
      priority: "recommended",
      rationale: "Supports cardiovascular health, reduces inflammation, aids recovery.",
      goal_alignment: ["recovery", "general health"],
      dosage_adjustment: null,
      timing_notes: "With meals",
      warnings: []
    }
  ],
  interaction_warnings: [],
  goal_coverage: {
    "muscle building": ["creatine"],
    "recovery": ["magnesium", "omega3"],
    "general health": ["vitamin_d3", "omega3"]
  }
};

export const MOCK_RECOVERY_ANALYSIS_RESPONSE = {
  analysis_summary: "Your recovery data shows that sauna sessions have the strongest positive impact on your HRV and sleep quality. Cold plunge sessions also show benefit, particularly when done in the afternoon. The combination of sauna followed by cold plunge appears most effective based on your data.",
  correlation_insights: [
    {
      finding: "Sauna sessions correlate with +8ms HRV improvement next day",
      strength: "strong",
      recommendation: "Continue 3-4 sauna sessions per week at 15-20 minutes",
      data_points: 12
    },
    {
      finding: "Afternoon cold plunge shows better sleep quality than morning",
      strength: "moderate",
      recommendation: "Schedule cold plunge sessions between 2-5 PM",
      data_points: 8
    }
  ],
  overall_recommendations: [
    "Maintain current sauna frequency of 3-4x per week",
    "Shift cold plunge sessions to afternoon when possible",
    "Consider adding contrast therapy (sauna + cold) 2x per week"
  ],
  optimal_protocol: {
    weekly_frequency: {
      sauna: 4,
      cold_plunge: 3,
      massage: 1
    },
    timing_recommendations: [
      "Sauna: Evening, 2+ hours before bed",
      "Cold plunge: Afternoon, not immediately post-workout for hypertrophy goals"
    ],
    combination_synergies: [
      "Sauna followed by cold plunge shows enhanced parasympathetic activation"
    ]
  }
};

export const MOCK_PDF_PARSE_RESPONSE = {
  provider: "quest",
  test_date: "2026-01-15",
  patient_name: "John Doe",
  ordering_physician: "Dr. Smith",
  biomarkers: [
    {
      name: "Vitamin D, 25-Hydroxy",
      value: 32,
      unit: "ng/mL",
      reference_range: "30-100",
      reference_low: 30,
      reference_high: 100,
      flag: "normal",
      category: "Vitamins"
    },
    {
      name: "Total Cholesterol",
      value: 185,
      unit: "mg/dL",
      reference_range: "<200",
      reference_low: null,
      reference_high: 200,
      flag: "normal",
      category: "Lipid Panel"
    },
    {
      name: "HDL Cholesterol",
      value: 62,
      unit: "mg/dL",
      reference_range: ">40",
      reference_low: 40,
      reference_high: null,
      flag: "normal",
      category: "Lipid Panel"
    },
    {
      name: "LDL Cholesterol",
      value: 95,
      unit: "mg/dL",
      reference_range: "<100",
      reference_low: null,
      reference_high: 100,
      flag: "normal",
      category: "Lipid Panel"
    },
    {
      name: "Triglycerides",
      value: 140,
      unit: "mg/dL",
      reference_range: "<150",
      reference_low: null,
      reference_high: 150,
      flag: "normal",
      category: "Lipid Panel"
    },
    {
      name: "Glucose",
      value: 92,
      unit: "mg/dL",
      reference_range: "70-100",
      reference_low: 70,
      reference_high: 100,
      flag: "normal",
      category: "Metabolic"
    },
    {
      name: "TSH",
      value: 2.1,
      unit: "mIU/L",
      reference_range: "0.4-4.0",
      reference_low: 0.4,
      reference_high: 4.0,
      flag: "normal",
      category: "Thyroid"
    },
    {
      name: "Testosterone, Total",
      value: 650,
      unit: "ng/dL",
      reference_range: "300-1000",
      reference_low: 300,
      reference_high: 1000,
      flag: "normal",
      category: "Hormones"
    }
  ],
  confidence: "high",
  parsing_notes: []
};

export const mockAnthropicClient = createMockAnthropicClient();
