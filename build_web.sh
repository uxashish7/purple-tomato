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
flutter build web --release --no-tree-shake-icons \
  --dart-define=UPSTOX_API_KEY="$UPSTOX_API_KEY" \
  --dart-define=UPSTOX_API_SECRET="$UPSTOX_API_SECRET" \
  --dart-define=UPSTOX_REDIRECT_URI="$UPSTOX_REDIRECT_URI" \
  --dart-define=GEMINI_API_KEY="$GEMINI_API_KEY" \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  --dart-define=ALPHA_VANTAGE_API_KEY="$ALPHA_VANTAGE_API_KEY"

echo "=== Build Complete ==="
