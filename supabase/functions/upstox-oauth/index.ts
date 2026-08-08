import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  // Handle CORS preflight request
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { code, redirectUri } = await req.json();

    if (!code) {
      return new Response(
        JSON.stringify({ error: "Missing authorization code" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const apiKey = Deno.env.get("UPSTOX_API_KEY");
    const apiSecret = Deno.env.get("UPSTOX_API_SECRET");
    // Use server-side redirect URI if set; fall back to client-provided value
    const serverRedirectUri = Deno.env.get("UPSTOX_REDIRECT_URI");

    if (!apiKey || !apiSecret) {
      return new Response(
        JSON.stringify({ error: "Upstox API key or secret not configured on server" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Prefer server-side redirect URI (single source of truth)
    const effectiveRedirectUri = serverRedirectUri || redirectUri || "";

    console.log(`[upstox-oauth] Exchanging code (${code.substring(0, 6)}...) with redirect_uri=${effectiveRedirectUri}`);

    const params = new URLSearchParams();
    params.append("code", code);
    params.append("client_id", apiKey);
    params.append("client_secret", apiSecret);
    params.append("redirect_uri", effectiveRedirectUri);
    params.append("grant_type", "authorization_code");

    const upstoxResponse = await fetch("https://api.upstox.com/v2/login/authorization/token", {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        "Accept": "application/json",
      },
      body: params.toString(),
    });

    const data = await upstoxResponse.json();

    console.log(`[upstox-oauth] Upstox response status: ${upstoxResponse.status}`);
    console.log(`[upstox-oauth] Upstox response body: ${JSON.stringify(data)}`);

    if (!upstoxResponse.ok) {
      return new Response(
        JSON.stringify({ error: "Upstox token exchange failed", details: data }),
        { status: upstoxResponse.status, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    return new Response(
      JSON.stringify({ access_token: data.access_token, raw: data }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error(`[upstox-oauth] Error: ${error.message}`);
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
