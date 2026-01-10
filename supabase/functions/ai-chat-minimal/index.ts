// Minimal standalone AI Chat function - no external deps
Deno.serve(async (req) => {
  try {
    const { message, athlete_id, session_id } = await req.json();

    const openaiKey = Deno.env.get('OPENAI_API_KEY');
    if (!openaiKey) {
      return new Response(JSON.stringify({success: false, error: 'API key not configured'}), {
        headers: {'Content-Type': 'application/json'},
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
      headers: {'Content-Type': 'application/json'}
    });

  } catch (error) {
    return new Response(JSON.stringify({
      success: false,
      error: error.message
    }), {
      headers: {'Content-Type': 'application/json'},
      status: 500
    });
  }
});
