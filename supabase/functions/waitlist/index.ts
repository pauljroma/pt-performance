import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"
import { SMTPClient } from "https://deno.land/x/denomailer@1.6.0/mod.ts"
import { corsHeaders, handleCors } from "../_shared/cors.ts"

// Branded confirmation email HTML - Dark theme with visible branding
const getConfirmationEmailHTML = (email: string) => `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="margin: 0; padding: 0; background: #0A0A0F; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background: #0A0A0F; padding: 40px 20px;">
    <tr>
      <td align="center">
        <table width="100%" cellpadding="0" cellspacing="0" style="max-width: 500px; background: #1C1C28; border-radius: 24px; overflow: hidden; box-shadow: 0 20px 60px rgba(0,0,0,0.5);">
          <!-- Header with gradient background -->
          <tr>
            <td style="background: linear-gradient(135deg, #007AFF 0%, #00D4AA 100%); padding: 40px 40px 32px; text-align: center;">
              <img src="https://getkorza.app/icon.png" alt="Korza Training" width="72" height="72" style="width: 72px; height: 72px; border-radius: 16px; margin-bottom: 16px; box-shadow: 0 8px 24px rgba(0,0,0,0.3);">
              <h1 style="margin: 0; font-size: 36px; font-weight: 800; color: #FFFFFF; letter-spacing: -0.5px;">Korza Training</h1>
              <p style="margin: 8px 0 0 0; font-size: 14px; color: rgba(255,255,255,0.9);">Smarter Training</p>
            </td>
          </tr>

          <!-- Content -->
          <tr>
            <td style="padding: 40px;">
              <!-- Welcome message -->
              <table width="100%" cellpadding="0" cellspacing="0">
                <tr>
                  <td align="center" style="padding-bottom: 20px;">
                    <span style="font-size: 56px;">🎉</span>
                  </td>
                </tr>
                <tr>
                  <td align="center" style="padding-bottom: 12px;">
                    <h2 style="margin: 0; font-size: 26px; font-weight: 700; color: #FFFFFF;">You're on the list!</h2>
                  </td>
                </tr>
                <tr>
                  <td align="center" style="padding-bottom: 32px;">
                    <p style="margin: 0; font-size: 16px; line-height: 1.6; color: #AAAAAA;">
                      Thanks for joining the Korza Training waitlist. You'll be among the first to experience smarter training when we launch.
                    </p>
                  </td>
                </tr>
              </table>

              <!-- What's coming -->
              <table width="100%" cellpadding="0" cellspacing="0" style="background: #2A2A38; border-radius: 16px; padding: 24px;">
                <tr>
                  <td>
                    <p style="margin: 0 0 16px 0; font-size: 13px; font-weight: 700; color: #00D4AA; text-transform: uppercase; letter-spacing: 1px;">What's coming</p>
                    <table width="100%" cellpadding="0" cellspacing="0">
                      <tr>
                        <td style="padding: 10px 0; color: #DDDDDD; font-size: 15px;">
                          📊 &nbsp; Daily readiness scores based on your data
                        </td>
                      </tr>
                      <tr>
                        <td style="padding: 10px 0; color: #DDDDDD; font-size: 15px;">
                          🎯 &nbsp; Adaptive workouts that evolve with you
                        </td>
                      </tr>
                      <tr>
                        <td style="padding: 10px 0; color: #DDDDDD; font-size: 15px;">
                          💡 &nbsp; AI-powered recovery insights
                        </td>
                      </tr>
                    </table>
                  </td>
                </tr>
              </table>

              <!-- CTA -->
              <table width="100%" cellpadding="0" cellspacing="0" style="padding-top: 32px;">
                <tr>
                  <td align="center">
                    <p style="margin: 0; font-size: 14px; color: #888888;">
                      We'll email you when Korza Training is ready.<br>Stay tuned!
                    </p>
                  </td>
                </tr>
              </table>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="padding: 24px 40px; background: #12121A; border-top: 1px solid #2A2A38;">
              <table width="100%" cellpadding="0" cellspacing="0">
                <tr>
                  <td align="center">
                    <p style="margin: 0; font-size: 12px; color: #666666;">
                      © 2026 Korza Training · Smarter Training<br>
                      <a href="https://getkorza.app" style="color: #007AFF; text-decoration: none;">getkorza.app</a>
                    </p>
                  </td>
                </tr>
              </table>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>
`

async function sendConfirmationEmail(email: string) {
  const smtpHost = Deno.env.get('SMTP_HOST')
  const smtpPort = parseInt(Deno.env.get('SMTP_PORT') || '465')
  const smtpUser = Deno.env.get('SMTP_USER')
  const smtpPass = Deno.env.get('SMTP_PASS')
  const fromEmail = Deno.env.get('SMTP_FROM') || 'hello@getkorza.app'

  if (!smtpHost || !smtpUser || !smtpPass) {
    console.log('SMTP not configured, skipping confirmation email')
    console.log(`SMTP_HOST: ${smtpHost ? 'set' : 'missing'}`)
    console.log(`SMTP_USER: ${smtpUser ? 'set' : 'missing'}`)
    console.log(`SMTP_PASS: ${smtpPass ? 'set' : 'missing'}`)
    return false
  }

  console.log(`Attempting to send email to ${email} via ${smtpHost}:${smtpPort}`)

  try {
    const client = new SMTPClient({
      connection: {
        hostname: smtpHost,
        port: smtpPort,
        tls: smtpPort === 465,
        auth: {
          username: smtpUser,
          password: smtpPass,
        },
      },
    })

    await client.send({
      from: fromEmail,
      to: email,
      subject: "You're on the Korza Training waitlist! 🎉",
      html: getConfirmationEmailHTML(email),
    })

    await client.close()
    console.log(`✅ Confirmation email sent to ${email}`)
    return true
  } catch (error) {
    console.error('❌ Failed to send confirmation email:', error)
    console.error('Error details:', JSON.stringify(error, null, 2))
    return false
  }
}

serve(async (req) => {
  // Handle CORS preflight
  const corsResponse = handleCors(req)
  if (corsResponse) return corsResponse

  const origin = req.headers.get('Origin')
  const headers = { ...corsHeaders(origin), 'Content-Type': 'application/json' }

  try {
    const { email, source = 'website' } = await req.json()

    if (!email || !email.includes('@')) {
      return new Response(
        JSON.stringify({ error: 'Valid email required' }),
        { status: 400, headers }
      )
    }

    const normalizedEmail = email.toLowerCase().trim()

    // Create Supabase client with service role for insert
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseKey)

    // Check if email already exists
    const { data: existing } = await supabase
      .from('waitlist')
      .select('email')
      .eq('email', normalizedEmail)
      .single()

    if (existing) {
      return new Response(
        JSON.stringify({ success: true, message: 'Already on waitlist' }),
        { status: 200, headers }
      )
    }

    // Insert new entry
    const { error } = await supabase
      .from('waitlist')
      .insert({ email: normalizedEmail, source })

    if (error) {
      console.error('Waitlist insert error:', error)
      throw error
    }

    // Send confirmation email (non-blocking)
    sendConfirmationEmail(normalizedEmail).catch(console.error)

    return new Response(
      JSON.stringify({ success: true, message: 'Added to waitlist' }),
      { status: 200, headers }
    )

  } catch (error) {
    console.error('Error:', error)
    return new Response(
      JSON.stringify({ error: 'Failed to join waitlist' }),
      { status: 500, headers }
    )
  }
})
