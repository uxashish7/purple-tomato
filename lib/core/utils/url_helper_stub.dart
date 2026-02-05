/// URL helper for checking current path - mobile stub
/// On mobile, we never have callback routes from browser

/// Check if current URL is the callback route - always false on mobile
bool isCallbackRoute() {
  return false;
}

/// Get the current URL for parsing - empty on mobile
String getCurrentUrl() {
  return '';
}
