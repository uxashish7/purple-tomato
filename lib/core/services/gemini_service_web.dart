// Platform-specific file operations for web
import 'dart:typed_data';

/// Read file bytes from path (Web platform - not supported)
Future<Uint8List?> readFileBytes(String path) async {
  // File system access not available on web
  // PDFs must be handled differently (use bytes directly from file_picker)
  print('File reading not supported on web platform');
  return null;
}
