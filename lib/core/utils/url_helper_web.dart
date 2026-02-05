/// URL helper for checking current path - web implementation
import 'dart:html' as html;

/// Check if current URL is the callback route
bool isCallbackRoute() {
  final path = html.window.location.pathname ?? '';
  return path.contains('/callback');
}

/// Get the current URL for parsing
String getCurrentUrl() {
  return html.window.location.href;
}
