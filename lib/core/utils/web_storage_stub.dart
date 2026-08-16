/// Stub for non-web platforms. Never actually called — [kIsWeb] guard in
/// HiveService ensures these methods are never reached on native.
class WebStorage {
  static String? read(String key) => null;
  static void write(String key, String value) {}
  static void remove(String key) {}
}
