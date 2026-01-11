#!/bin/bash
set -e

echo "=== Installing Flutter SDK ==="
git clone https://github.com/flutter/flutter.git -b stable --depth 1 flutter-sdk
export PATH="$PATH:$PWD/flutter-sdk/bin"

echo "=== Flutter Version ==="
flutter --version

echo "=== Getting Dependencies ==="
flutter pub get

echo "=== Building Web ==="
flutter build web --release --dart-define=GEMINI_API_KEY=$GEMINI_API_KEY

echo "=== Build Complete ==="
