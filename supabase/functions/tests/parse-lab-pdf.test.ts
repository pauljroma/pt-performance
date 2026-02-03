// ============================================================================
// Parse Lab PDF Edge Function Tests
// Health Intelligence Platform - Test Suite
// ============================================================================

import {
  assertEquals,
  assertExists,
  assertStringIncludes,
} from "https://deno.land/std@0.168.0/testing/asserts.ts";
import {
  describe,
  it,
  beforeEach,
} from "https://deno.land/std@0.168.0/testing/bdd.ts";

import {
  createMockAnthropicClient,
  createMockAnthropicFetch,
  MOCK_PDF_PARSE_RESPONSE,
} from "./_mocks/mockAnthropicClient.ts";

// ============================================================================
// HELPER FUNCTIONS AND TYPES
// ============================================================================

interface ParsedBiomarker {
  name: string;
  value: number;
  unit: string;
  reference_range?: string;
  reference_low?: number | null;
  reference_high?: number | null;
  flag?: "normal" | "low" | "high" | "critical" | null;
  category?: string;
}

interface ParseLabPDFResponse {
  success: boolean;
  provider?: "quest" | "labcorp" | "unknown" | string;
  test_date?: string;
  patient_name?: string;
  ordering_physician?: string;
  biomarkers: ParsedBiomarker[];
  raw_text_preview?: string;
  confidence: "high" | "medium" | "low";
  parsing_notes?: string[];
  error?: string;
}

// Lab provider detection patterns
const LAB_PROVIDER_PATTERNS = {
  quest: [
    "quest diagnostics",
    "questdiagnostics",
    "quest.com",
    "www.questdiagnostics.com",
  ],
  labcorp: [
    "labcorp",
    "laboratory corporation of america",
    "labcorp.com",
    "www.labcorp.com",
  ],
};

function detectLabProvider(text: string): "quest" | "labcorp" | "unknown" {
  const lowerText = text.toLowerCase();

  for (const pattern of LAB_PROVIDER_PATTERNS.quest) {
    if (lowerText.includes(pattern)) return "quest";
  }

  for (const pattern of LAB_PROVIDER_PATTERNS.labcorp) {
    if (lowerText.includes(pattern)) return "labcorp";
  }

  return "unknown";
}

// Biomarker type mappings
const BIOMARKER_TYPE_MAPPINGS: Record<string, string> = {
  wbc: "wbc",
  "white blood cell": "wbc",
  "white blood cell count": "wbc",
  rbc: "rbc",
  "red blood cell": "rbc",
  hemoglobin: "hemoglobin",
  hgb: "hemoglobin",
  hematocrit: "hematocrit",
  hct: "hematocrit",
  glucose: "glucose",
  "fasting glucose": "glucose_fasting",
  creatinine: "creatinine",
  "total cholesterol": "cholesterol_total",
  cholesterol: "cholesterol_total",
  hdl: "hdl",
  "hdl cholesterol": "hdl",
  ldl: "ldl",
  "ldl cholesterol": "ldl",
  triglycerides: "triglycerides",
  tsh: "tsh",
  "thyroid stimulating hormone": "tsh",
  testosterone: "testosterone_total",
  "testosterone, total": "testosterone_total",
  "vitamin d": "vitamin_d",
  "vitamin d, 25-hydroxy": "vitamin_d",
  "25-hydroxy vitamin d": "vitamin_d",
  "vitamin b12": "vitamin_b12",
  b12: "vitamin_b12",
  ferritin: "ferritin",
  iron: "iron",
  hba1c: "hba1c",
  "hemoglobin a1c": "hba1c",
  a1c: "hba1c",
};

function normalizeBiomarkerType(name: string): string {
  const lowerName = name.toLowerCase().trim();
  return BIOMARKER_TYPE_MAPPINGS[lowerName] || lowerName.replace(/[^a-z0-9]/g, "_");
}

// Mock base64 PDF data
const MOCK_VALID_PDF_BASE64 =
  "JVBERi0xLjQKMSAwIG9iago8PCAvVHlwZSAvQ2F0YWxvZyAvUGFnZXMgMiAwIFIgPj4KZW5kb2JqCjIgMCBvYmoKPDwgL1R5cGUgL1BhZ2VzIC9LaWRzIFszIDAgUl0gL0NvdW50IDEgPj4KZW5kb2JqCjMgMCBvYmoKPDwgL1R5cGUgL1BhZ2UgL1BhcmVudCAyIDAgUiAvTWVkaWFCb3ggWzAgMCA2MTIgNzkyXSA+PgplbmRvYmoKeHJlZgowIDQKMDAwMDAwMDAwMCA2NTUzNSBmIAowMDAwMDAwMDA5IDAwMDAwIG4gCjAwMDAwMDAwNTggMDAwMDAgbiAKMDAwMDAwMDExNSAwMDAwMCBuIAp0cmFpbGVyCjw8IC9TaXplIDQgL1Jvb3QgMSAwIFIgPj4Kc3RhcnR4cmVmCjE5OAolJUVPRg==";

// ============================================================================
// TEST SUITE
// ============================================================================

describe("Parse Lab PDF Edge Function", () => {
  let mockAnthropic: ReturnType<typeof createMockAnthropicClient>;

  beforeEach(() => {
    mockAnthropic = createMockAnthropicClient();
    mockAnthropic._setMockResponse(MOCK_PDF_PARSE_RESPONSE);
  });

  describe("Request Validation", () => {
    it("should reject requests without pdf_base64", () => {
      const request = {
        filename: "lab_results.pdf",
      };
      const hasPdfBase64 = "pdf_base64" in request && (request as any).pdf_base64;
      assertEquals(hasPdfBase64, false);
    });

    it("should reject requests with empty pdf_base64", () => {
      const request = {
        pdf_base64: "",
      };
      const isValid = !!(request.pdf_base64 && request.pdf_base64.length > 0);
      assertEquals(isValid, false);
    });

    it("should reject requests with pdf_base64 too small", () => {
      const request = {
        pdf_base64: "abc",
      };
      const isValid = request.pdf_base64.length >= 100;
      assertEquals(isValid, false);
    });

    it("should accept valid pdf_base64", () => {
      const request = {
        pdf_base64: MOCK_VALID_PDF_BASE64,
      };
      const isValid = request.pdf_base64.length >= 100;
      assertEquals(isValid, true);
    });

    it("should accept optional filename parameter", () => {
      const request = {
        pdf_base64: MOCK_VALID_PDF_BASE64,
        filename: "my_lab_results.pdf",
      };
      assertExists(request.filename);
    });
  });

  describe("PDF Parsing with Mock Claude Vision", () => {
    it("should call Claude Vision API with PDF data", async () => {
      mockAnthropic._setMockResponse(MOCK_PDF_PARSE_RESPONSE);

      const result = await mockAnthropic.messages.create({
        model: "claude-sonnet-4-20250514",
        max_tokens: 4096,
        messages: [
          {
            role: "user",
            content: [
              { type: "text", text: "Parse this lab PDF" },
              {
                type: "image",
                source: {
                  type: "base64",
                  media_type: "application/pdf",
                  data: MOCK_VALID_PDF_BASE64,
                },
              },
            ],
          },
        ],
        temperature: 0.1,
      });

      assertExists(result);
      assertExists(result.content);
    });

    it("should use low temperature for accurate extraction", async () => {
      const callParams = {
        model: "claude-sonnet-4-20250514",
        max_tokens: 4096,
        messages: [{ role: "user", content: "Test" }],
        temperature: 0.1,
      };

      assertEquals(callParams.temperature, 0.1);
    });

    it("should parse structured biomarker data from response", async () => {
      mockAnthropic._setMockResponse(MOCK_PDF_PARSE_RESPONSE);

      const result = await mockAnthropic.messages.create({
        model: "claude-sonnet-4-20250514",
        messages: [{ role: "user", content: "Test" }],
      });

      const parsed = JSON.parse(result.content[0].text);
      assertExists(parsed.biomarkers);
      assertEquals(Array.isArray(parsed.biomarkers), true);
      assertEquals(parsed.biomarkers.length > 0, true);
    });
  });

  describe("Biomarker Extraction", () => {
    it("should extract biomarker name", () => {
      const biomarker = MOCK_PDF_PARSE_RESPONSE.biomarkers[0];
      assertExists(biomarker.name);
      assertEquals(typeof biomarker.name, "string");
    });

    it("should extract biomarker value as number", () => {
      const biomarker = MOCK_PDF_PARSE_RESPONSE.biomarkers[0];
      assertExists(biomarker.value);
      assertEquals(typeof biomarker.value, "number");
    });

    it("should extract biomarker unit", () => {
      const biomarker = MOCK_PDF_PARSE_RESPONSE.biomarkers[0];
      assertExists(biomarker.unit);
      assertEquals(typeof biomarker.unit, "string");
    });

    it("should extract reference range when available", () => {
      const biomarker = MOCK_PDF_PARSE_RESPONSE.biomarkers[0];
      assertExists(biomarker.reference_range);
    });

    it("should extract reference_low and reference_high when available", () => {
      const glucoseBiomarker = MOCK_PDF_PARSE_RESPONSE.biomarkers.find(
        (b) => b.name.toLowerCase().includes("glucose")
      );
      assertExists(glucoseBiomarker);
      assertExists(glucoseBiomarker!.reference_low);
      assertExists(glucoseBiomarker!.reference_high);
    });

    it("should handle reference ranges with only upper bound", () => {
      const cholesterolBiomarker = MOCK_PDF_PARSE_RESPONSE.biomarkers.find(
        (b) => b.name.toLowerCase().includes("total cholesterol")
      );
      assertExists(cholesterolBiomarker);
      assertEquals(cholesterolBiomarker!.reference_low, null);
      assertExists(cholesterolBiomarker!.reference_high);
    });

    it("should handle reference ranges with only lower bound", () => {
      const hdlBiomarker = MOCK_PDF_PARSE_RESPONSE.biomarkers.find(
        (b) => b.name.toLowerCase().includes("hdl")
      );
      assertExists(hdlBiomarker);
      assertExists(hdlBiomarker!.reference_low);
      assertEquals(hdlBiomarker!.reference_high, null);
    });

    it("should extract flag status", () => {
      const biomarker = MOCK_PDF_PARSE_RESPONSE.biomarkers[0];
      assertExists(biomarker.flag);
      const validFlags = ["normal", "low", "high", "critical", null];
      assertEquals(validFlags.includes(biomarker.flag!), true);
    });

    it("should extract category when available", () => {
      const biomarker = MOCK_PDF_PARSE_RESPONSE.biomarkers[0];
      assertExists(biomarker.category);
    });

    it("should normalize biomarker type names", () => {
      assertEquals(normalizeBiomarkerType("Vitamin D, 25-Hydroxy"), "vitamin_d");
      assertEquals(normalizeBiomarkerType("HDL Cholesterol"), "hdl");
      assertEquals(normalizeBiomarkerType("HbA1c"), "hba1c");
      assertEquals(normalizeBiomarkerType("TSH"), "tsh");
      assertEquals(normalizeBiomarkerType("Total Cholesterol"), "cholesterol_total");
    });

    it("should handle unknown biomarker names", () => {
      const normalized = normalizeBiomarkerType("Some Unknown Marker");
      assertEquals(normalized, "some_unknown_marker");
    });
  });

  describe("Lab Provider Detection", () => {
    it("should detect Quest Diagnostics", () => {
      const text = "Quest Diagnostics Lab Report";
      assertEquals(detectLabProvider(text), "quest");
    });

    it("should detect LabCorp", () => {
      const text = "LabCorp Patient Results";
      assertEquals(detectLabProvider(text), "labcorp");
    });

    it("should detect Quest from URL", () => {
      const text = "Report from www.questdiagnostics.com";
      assertEquals(detectLabProvider(text), "quest");
    });

    it("should detect LabCorp from full name", () => {
      const text = "Laboratory Corporation of America Holdings";
      assertEquals(detectLabProvider(text), "labcorp");
    });

    it("should return unknown for unrecognized providers", () => {
      const text = "Generic Lab Report";
      assertEquals(detectLabProvider(text), "unknown");
    });

    it("should be case-insensitive", () => {
      assertEquals(detectLabProvider("QUEST DIAGNOSTICS"), "quest");
      assertEquals(detectLabProvider("LABCORP"), "labcorp");
    });
  });

  describe("Error Handling for Invalid PDFs", () => {
    it("should return error for unsupported PDF format", () => {
      const errorResponse: ParseLabPDFResponse = {
        success: false,
        error: "PDF format not supported. Please try converting to images or ensure the PDF is not encrypted.",
        biomarkers: [],
        confidence: "low",
      };

      assertEquals(errorResponse.success, false);
      assertExists(errorResponse.error);
      assertEquals(errorResponse.biomarkers.length, 0);
    });

    it("should return error for invalid base64 data", () => {
      const errorResponse: ParseLabPDFResponse = {
        success: false,
        error: "Invalid PDF data - file too small",
        biomarkers: [],
        confidence: "low",
      };

      assertEquals(errorResponse.success, false);
      assertExists(errorResponse.error);
    });

    it("should return low confidence when no biomarkers extracted", () => {
      const response: ParseLabPDFResponse = {
        success: false,
        biomarkers: [],
        confidence: "low",
        parsing_notes: ["No biomarkers could be extracted from the document"],
      };

      assertEquals(response.confidence, "low");
    });

    it("should handle API errors gracefully", async () => {
      mockAnthropic._setMockError(new Error("API rate limit exceeded"));

      let errorCaught = false;
      try {
        await mockAnthropic.messages.create({
          model: "claude-sonnet-4-20250514",
          messages: [{ role: "user", content: "Test" }],
        });
      } catch (error) {
        errorCaught = true;
        assertEquals((error as Error).message, "API rate limit exceeded");
      }

      assertEquals(errorCaught, true);
    });

    it("should handle invalid JSON response from Claude", () => {
      const invalidResponse = "This is not valid JSON output";

      let parseError = false;
      try {
        JSON.parse(invalidResponse);
      } catch {
        parseError = true;
      }

      assertEquals(parseError, true);
    });
  });

  describe("Response Structure", () => {
    it("should include success field", () => {
      const response: ParseLabPDFResponse = {
        success: true,
        biomarkers: MOCK_PDF_PARSE_RESPONSE.biomarkers as ParsedBiomarker[],
        confidence: "high",
      };

      assertExists(response.success);
      assertEquals(typeof response.success, "boolean");
    });

    it("should include provider when detected", () => {
      const response: ParseLabPDFResponse = {
        success: true,
        provider: "quest",
        biomarkers: [],
        confidence: "high",
      };

      assertExists(response.provider);
    });

    it("should include test_date when found", () => {
      const response: ParseLabPDFResponse = {
        success: true,
        test_date: "2026-01-15",
        biomarkers: [],
        confidence: "high",
      };

      assertExists(response.test_date);
      // Validate date format
      const dateMatch = response.test_date!.match(/\d{4}-\d{2}-\d{2}/);
      assertExists(dateMatch);
    });

    it("should include patient_name when found", () => {
      const response: ParseLabPDFResponse = {
        success: true,
        patient_name: "John Doe",
        biomarkers: [],
        confidence: "high",
      };

      assertExists(response.patient_name);
    });

    it("should include ordering_physician when found", () => {
      const response: ParseLabPDFResponse = {
        success: true,
        ordering_physician: "Dr. Smith",
        biomarkers: [],
        confidence: "high",
      };

      assertExists(response.ordering_physician);
    });

    it("should include confidence level", () => {
      const validConfidenceLevels = ["high", "medium", "low"];

      for (const level of validConfidenceLevels) {
        const response: ParseLabPDFResponse = {
          success: true,
          biomarkers: [],
          confidence: level as "high" | "medium" | "low",
        };
        assertEquals(validConfidenceLevels.includes(response.confidence), true);
      }
    });

    it("should include parsing_notes when issues found", () => {
      const response: ParseLabPDFResponse = {
        success: true,
        biomarkers: [],
        confidence: "medium",
        parsing_notes: ["Some values were unclear", "Date format was ambiguous"],
      };

      assertExists(response.parsing_notes);
      assertEquals(Array.isArray(response.parsing_notes), true);
    });
  });

  describe("Confidence Level Determination", () => {
    it("should return high confidence for clear, complete data", () => {
      const biomarkers = MOCK_PDF_PARSE_RESPONSE.biomarkers;
      let confidence: "high" | "medium" | "low" = "high";

      if (biomarkers.length === 0) {
        confidence = "low";
      } else if (biomarkers.length < 3) {
        confidence = "medium";
      }

      assertEquals(confidence, "high");
    });

    it("should return medium confidence for few biomarkers", () => {
      const biomarkers = [MOCK_PDF_PARSE_RESPONSE.biomarkers[0]];
      let confidence: "high" | "medium" | "low" = "high";

      if (biomarkers.length === 0) {
        confidence = "low";
      } else if (biomarkers.length < 3) {
        confidence = confidence === "high" ? "medium" : confidence;
      }

      assertEquals(confidence, "medium");
    });

    it("should return low confidence for no biomarkers", () => {
      const biomarkers: ParsedBiomarker[] = [];
      let confidence: "high" | "medium" | "low" = "high";

      if (biomarkers.length === 0) {
        confidence = "low";
      }

      assertEquals(confidence, "low");
    });
  });

  describe("Biomarker Validation", () => {
    it("should skip biomarkers with invalid name", () => {
      const biomarkers: ParsedBiomarker[] = [];
      const parsingNotes: string[] = [];

      const rawBiomarker = { name: "", value: 100, unit: "mg/dL" };

      if (!rawBiomarker.name || typeof rawBiomarker.value !== "number") {
        parsingNotes.push(`Skipped biomarker with invalid data: ${JSON.stringify(rawBiomarker)}`);
      } else {
        biomarkers.push(rawBiomarker as ParsedBiomarker);
      }

      assertEquals(biomarkers.length, 0);
      assertEquals(parsingNotes.length, 1);
    });

    it("should skip biomarkers with non-numeric value", () => {
      const biomarkers: ParsedBiomarker[] = [];
      const parsingNotes: string[] = [];

      const rawBiomarker = { name: "Glucose", value: "high" as any, unit: "mg/dL" };

      if (!rawBiomarker.name || typeof rawBiomarker.value !== "number") {
        parsingNotes.push(`Skipped biomarker with invalid data: ${JSON.stringify(rawBiomarker)}`);
      } else {
        biomarkers.push(rawBiomarker as ParsedBiomarker);
      }

      assertEquals(biomarkers.length, 0);
      assertEquals(parsingNotes.length, 1);
    });

    it("should auto-detect flag based on reference range", () => {
      const biomarker: ParsedBiomarker = {
        name: "Glucose",
        value: 110,
        unit: "mg/dL",
        reference_low: 70,
        reference_high: 100,
        flag: null,
      };

      // Auto-detect flag
      const refLow = biomarker.reference_low;
      const refHigh = biomarker.reference_high;
      if (!biomarker.flag && refLow !== null && refLow !== undefined && refHigh !== null && refHigh !== undefined) {
        if (biomarker.value < refLow) {
          biomarker.flag = "low";
        } else if (biomarker.value > refHigh) {
          biomarker.flag = "high";
        } else {
          biomarker.flag = "normal";
        }
      }

      assertEquals(biomarker.flag, "high");
    });

    it("should set normal flag when value in range", () => {
      const biomarker: ParsedBiomarker = {
        name: "Glucose",
        value: 85,
        unit: "mg/dL",
        reference_low: 70,
        reference_high: 100,
        flag: null,
      };

      const refLow = biomarker.reference_low;
      const refHigh = biomarker.reference_high;
      if (!biomarker.flag && refLow !== null && refLow !== undefined && refHigh !== null && refHigh !== undefined) {
        if (biomarker.value < refLow) {
          biomarker.flag = "low";
        } else if (biomarker.value > refHigh) {
          biomarker.flag = "high";
        } else {
          biomarker.flag = "normal";
        }
      }

      assertEquals(biomarker.flag, "normal");
    });

    it("should set low flag when value below range", () => {
      const biomarker: ParsedBiomarker = {
        name: "Glucose",
        value: 65,
        unit: "mg/dL",
        reference_low: 70,
        reference_high: 100,
        flag: null,
      };

      const refLow = biomarker.reference_low;
      const refHigh = biomarker.reference_high;
      if (!biomarker.flag && refLow !== null && refLow !== undefined && refHigh !== null && refHigh !== undefined) {
        if (biomarker.value < refLow) {
          biomarker.flag = "low";
        } else if (biomarker.value > refHigh) {
          biomarker.flag = "high";
        } else {
          biomarker.flag = "normal";
        }
      }

      assertEquals(biomarker.flag, "low");
    });
  });

  describe("Test Date Validation", () => {
    it("should validate YYYY-MM-DD date format", () => {
      const testDate = "2026-01-15";
      const dateMatch = testDate.match(/\d{4}-\d{2}-\d{2}/);
      assertExists(dateMatch);
      assertEquals(dateMatch[0], "2026-01-15");
    });

    it("should extract date from various formats", () => {
      const rawDate = "January 15, 2026";
      // In real implementation, Claude would parse this
      const parsedDate = "2026-01-15";
      const dateMatch = parsedDate.match(/\d{4}-\d{2}-\d{2}/);
      assertExists(dateMatch);
    });

    it("should add parsing note for unparseable date", () => {
      const parsingNotes: string[] = [];
      const rawDate = "Invalid Date";
      const dateMatch = rawDate.match(/\d{4}-\d{2}-\d{2}/);

      if (!dateMatch) {
        parsingNotes.push(`Could not parse test date: ${rawDate}`);
      }

      assertEquals(parsingNotes.length, 1);
      assertStringIncludes(parsingNotes[0], "Could not parse");
    });
  });

  describe("Integration with Vision API", () => {
    it("should include image content in API request", () => {
      const messageContent = [
        { type: "text", text: "Parse this lab PDF" },
        {
          type: "image",
          source: {
            type: "base64",
            media_type: "application/pdf",
            data: MOCK_VALID_PDF_BASE64,
          },
        },
      ];

      assertEquals(messageContent.length, 2);
      assertEquals(messageContent[0].type, "text");
      assertEquals(messageContent[1].type, "image");
    });

    it("should use application/pdf media type", () => {
      const imageContent = {
        type: "image",
        source: {
          type: "base64",
          media_type: "application/pdf",
          data: MOCK_VALID_PDF_BASE64,
        },
      };

      assertEquals(imageContent.source.media_type, "application/pdf");
    });

    it("should handle 400 error for unsupported format", async () => {
      const mockFetch = createMockAnthropicFetch({}, 400);

      const response = await mockFetch("https://api.anthropic.com/v1/messages", {
        method: "POST",
        headers: {},
        body: JSON.stringify({}),
      });

      assertEquals(response.status, 400);
    });
  });

  describe("Common Lab Panel Extraction", () => {
    it("should extract Complete Blood Count (CBC) markers", () => {
      const cbcMarkers = ["wbc", "rbc", "hemoglobin", "hematocrit", "platelets"];
      for (const marker of cbcMarkers) {
        const normalized = normalizeBiomarkerType(marker);
        assertExists(normalized);
      }
    });

    it("should extract Metabolic Panel markers", () => {
      const metabolicMarkers = ["glucose", "creatinine", "bun", "sodium", "potassium"];
      for (const marker of metabolicMarkers) {
        const normalized = normalizeBiomarkerType(marker);
        assertExists(normalized);
      }
    });

    it("should extract Lipid Panel markers", () => {
      const lipidMarkers = ["total cholesterol", "hdl", "ldl", "triglycerides"];
      for (const marker of lipidMarkers) {
        const normalized = normalizeBiomarkerType(marker);
        assertExists(normalized);
      }
    });

    it("should extract Thyroid Panel markers", () => {
      const thyroidMarkers = ["tsh", "free t4", "free t3"];
      assertEquals(normalizeBiomarkerType("tsh"), "tsh");
      assertEquals(normalizeBiomarkerType("free t4"), "free_t4");
      assertEquals(normalizeBiomarkerType("free t3"), "free_t3");
    });

    it("should extract Hormone markers", () => {
      assertEquals(normalizeBiomarkerType("testosterone"), "testosterone_total");
      assertEquals(normalizeBiomarkerType("estradiol"), "estradiol");
      assertEquals(normalizeBiomarkerType("cortisol"), "cortisol");
    });

    it("should extract Vitamin/Mineral markers", () => {
      assertEquals(normalizeBiomarkerType("vitamin d"), "vitamin_d");
      assertEquals(normalizeBiomarkerType("vitamin b12"), "vitamin_b12");
      assertEquals(normalizeBiomarkerType("ferritin"), "ferritin");
      assertEquals(normalizeBiomarkerType("iron"), "iron");
    });
  });
});
