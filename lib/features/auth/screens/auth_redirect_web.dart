import 'dart:html' as html;

/// Web-specific helper for redirecting to Upstox OAuth
void redirectToUpstox(String authUrl) {
  // Redirect same tab to Upstox authorization URL
  html.window.location.href = authUrl;
}
