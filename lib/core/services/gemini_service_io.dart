// Platform-specific file operations for mobile/desktop
import 'dart:io';
import 'dart:typed_data';

/// Read file bytes from path (IO platforms)
Future<Uint8List?> readFileBytes(String path) async {
  try {
    final file = File(path);
    return await file.readAsBytes();
  } catch (e) {
    print('Error reading file: $e');
    return null;
  }
}
