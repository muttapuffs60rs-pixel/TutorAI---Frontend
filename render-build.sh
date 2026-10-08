#!/usr/bin/env bash
set -euo pipefail

# Match the SDK used to validate this release locally.
FLUTTER_SDK_DIR="$(mktemp -d)"
git clone --depth 1 --branch 3.41.6 https://github.com/flutter/flutter.git "$FLUTTER_SDK_DIR"
export PATH="$FLUTTER_SDK_DIR/bin:$PATH"
export CI=true
flutter config --no-analytics
flutter pub get --enforce-lockfile
flutter build web --release
