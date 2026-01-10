// AI Meal Parser Handler
// Build 138 - Nutrition Tracking
// Parses natural language meal descriptions into structured macro data
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type'
};
serve(async (req)=>{
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', {
      headers: corsHeaders
    });
  }
  try {
    const { description, image_url } = await req.json();
    if (!description || description.trim().length === 0) {
      return new Response(JSON.stringify({
        error: 'description is required and cannot be empty'
      }), {
        status: 400,
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json'
        }
      });
    }
    // Determine which OpenAI model to use based on whether image is provided
    const hasImage = image_url && image_url.trim().length > 0;
    const model = hasImage ? 'gpt-4-vision-preview' : 'gpt-4o-mini';
    // Build the analysis prompt
    const systemPrompt = `You are a nutrition analysis expert. Parse meal descriptions into structured data with accurate macro estimates.

Your task:
1. Identify the meal type (breakfast/lunch/dinner/snack)
2. List individual food items
3. Estimate total calories and macronutrients (protein, carbs, fats in grams)
4. Assess confidence based on description specificity

Rules:
- Use standard portion sizes (e.g., "chicken breast" = 6oz cooked, "rice" = 1 cup cooked)
- Be conservative with estimates when portions are unclear
- Round all macros to 1 decimal place
- Consider cooking methods (fried vs grilled affects fats/calories)
- If description is vague ("I had lunch"), provide low confidence with generic estimates
- Total macros should add up properly (protein*4 + carbs*4 + fats*9 ≈ calories)

Confidence levels:
- HIGH: Specific foods with portions ("8oz grilled chicken, 1 cup brown rice, 1 cup broccoli")
- MEDIUM: Specific foods without portions ("chicken breast with rice and vegetables")
- LOW: Vague descriptions ("lunch", "had some food", "ate dinner")

Return ONLY valid JSON with this exact structure:
{
  "meal_type": "breakfast|lunch|dinner|snack",
  "foods": ["food item 1", "food item 2", ...],
  "calories": number,
  "protein": number (grams, 1 decimal),
  "carbs": number (grams, 1 decimal),
  "fats": number (grams, 1 decimal),
  "ai_confidence": "high|medium|low"
}`;
    let messages;
    if (hasImage) {
      // GPT-4 Vision mode - include image
      messages = [
        {
          role: 'user',
          content: [
            {
              type: 'text',
              text: `${systemPrompt}\n\nMeal description: "${description}"\n\nAnalyze the provided image along with the description to estimate macros.`
            },
            {
              type: 'image_url',
              image_url: {
                url: image_url,
                detail: 'low' // Use low detail for faster processing and lower cost
              }
            }
          ]
        }
      ];
    } else {
      // Text-only mode
      messages = [
        {
          role: 'system',
          content: systemPrompt
        },
        {
          role: 'user',
          content: `Meal description: "${description}"\n\nProvide the structured JSON response.`
        }
      ];
    }
    // Call OpenAI API
    const openaiResponse = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${Deno.env.get('OPENAI_API_KEY')}`
      },
      body: JSON.stringify({
        model: model,
        messages: messages,
        max_tokens: 500,
        temperature: 0.3,
        response_format: hasImage ? undefined : {
          type: 'json_object'
        } // Force JSON for text-only
      })
    });
    if (!openaiResponse.ok) {
      const errorText = await openaiResponse.text();
      console.error('OpenAI API error:', errorText);
      throw new Error(`OpenAI API failed: ${openaiResponse.status} - ${errorText}`);
    }
    const completion = await openaiResponse.json();
    const responseText = completion.choices[0].message.content;
    const tokensUsed = completion.usage?.total_tokens || 0;
    // Parse the JSON response
    let parsedMeal;
    try {
      // GPT-4 Vision sometimes wraps JSON in markdown code blocks
      const jsonMatch = responseText.match(/\{[\s\S]*\}/);
      const jsonText = jsonMatch ? jsonMatch[0] : responseText;
      parsedMeal = JSON.parse(jsonText);
    } catch (parseError) {
      console.error('Failed to parse OpenAI response:', responseText);
      throw new Error('Failed to parse AI response as JSON. Please try again.');
    }
    // Validate the response structure
    if (!parsedMeal.meal_type || !parsedMeal.foods || !Array.isArray(parsedMeal.foods)) {
      throw new Error('Invalid AI response structure');
    }
    if (typeof parsedMeal.calories !== 'number' || typeof parsedMeal.protein !== 'number' || typeof parsedMeal.carbs !== 'number' || typeof parsedMeal.fats !== 'number') {
      throw new Error('Invalid macro values in AI response');
    }
    // Ensure macros are rounded to 1 decimal place
    parsedMeal.protein = Math.round(parsedMeal.protein * 10) / 10;
    parsedMeal.carbs = Math.round(parsedMeal.carbs * 10) / 10;
    parsedMeal.fats = Math.round(parsedMeal.fats * 10) / 10;
    parsedMeal.calories = Math.round(parsedMeal.calories);
    // Validate meal_type
    const validMealTypes = [
      'breakfast',
      'lunch',
      'dinner',
      'snack'
    ];
    if (!validMealTypes.includes(parsedMeal.meal_type)) {
      parsedMeal.meal_type = 'snack' // Default fallback
      ;
    }
    // Validate confidence level
    const validConfidenceLevels = [
      'high',
      'medium',
      'low'
    ];
    if (!validConfidenceLevels.includes(parsedMeal.ai_confidence)) {
      parsedMeal.ai_confidence = 'medium' // Default fallback
      ;
    }
    // Log for debugging (can be viewed in Supabase logs)
    console.log('Meal parsed successfully:', {
      description,
      hasImage,
      model,
      tokensUsed,
      confidence: parsedMeal.ai_confidence
    });
    return new Response(JSON.stringify({
      success: true,
      parsed_meal: parsedMeal,
      model_used: model,
      tokens_used: tokensUsed
    }), {
      status: 200,
      headers: {
        ...corsHeaders,
        'Content-Type': 'application/json'
      }
    });
  } catch (error) {
    console.error('Error in ai-meal-parser:', error);
    const errorMessage = error instanceof Error ? error.message : 'Internal server error';
    return new Response(JSON.stringify({
      error: errorMessage,
      success: false
    }), {
      status: 500,
      headers: {
        ...corsHeaders,
        'Content-Type': 'application/json'
      }
    });
  }
});
