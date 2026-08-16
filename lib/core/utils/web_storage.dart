// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Web implementation of localStorage access using a fixed, stable key.
/// This file is only loaded on Flutter Web builds (via conditional import).
class WebStorage {
  static String? read(String key) {
    return html.window.localStorage[key];
  }

  static void write(String key, String value) {
    html.window.localStorage[key] = value;
  }

  static void remove(String key) {
    html.window.localStorage.remove(key);
  }
}
