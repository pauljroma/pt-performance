// Minimal standalone AI Chat function - no external deps
import { checkRateLimit, rateLimitResponse } from '../_shared/rate-limit.ts'
import { corsHeaders, handleCors } from '../_shared/cors.ts'

Deno.serve(async (req) => {
  // Handle CORS preflight
  const corsResponse = handleCors(req)
  if (corsResponse) return corsResponse

  const origin = req.headers.get('Origin')
  const headers = corsHeaders(origin)

  try {
    const { message, athlete_id, session_id } = await req.json();

    // Rate limit: 10 requests/minute for AI endpoints
    const rateLimitKey = athlete_id || req.headers.get('x-forwarded-for') || 'anonymous';
    const { allowed, resetMs } = checkRateLimit(`ai-chat-minimal:${rateLimitKey}`, { windowMs: 60_000, maxRequests: 10 });
    if (!allowed) return rateLimitResponse(resetMs);

    const openaiKey = Deno.env.get('OPENAI_API_KEY');
    if (!openaiKey) {
      return new Response(JSON.stringify({success: false, error: 'API key not configured'}), {
        headers: {...headers, 'Content-Type': 'application/json'},
        status: 500
      });
    }

    // Call OpenAI
    const openaiResponse = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${openaiKey}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        model: 'gpt-4-turbo-preview',
        messages: [{role: 'user', content: message}],
        max_tokens: 500,
        temperature: 0.7
      })
    });

    const data = await openaiResponse.json();
    const reply = data.choices?.[0]?.message?.content || 'Sorry, I couldn unable to respond.';

    return new Response(JSON.stringify({
      success: true,
      session_id: session_id || crypto.randomUUID(),
      message: reply
    }), {
      headers: {...headers, 'Content-Type': 'application/json'}
    });

  } catch (error) {
    return new Response(JSON.stringify({
      success: false,
      error: error.message
    }), {
      headers: {...headers, 'Content-Type': 'application/json'},
      status: 500
    });
  }
});
