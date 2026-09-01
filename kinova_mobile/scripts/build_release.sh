#!/usr/bin/env bash
# Build release artifacts for Play Store (AAB) and App Store (IPA).
set -euo pipefail

cd "$(dirname "$0")/.."

echo "==> KINOVA release build"
echo "    Version: $(grep '^version:' pubspec.yaml | awk '{print $2}')"
echo ""

if [[ "${1:-all}" == "android" || "${1:-all}" == "all" ]]; then
  if [[ ! -f android/key.properties ]]; then
    echo "⚠️  android/key.properties manquant — le AAB sera signé en debug."
    echo "   Copiez android/key.properties.example et créez votre keystore Play Store."
    echo ""
  fi
  echo "==> Building Android App Bundle (Play Store)..."
  flutter build appbundle --release
  echo "    → build/app/outputs/bundle/release/app-release.aab"
  echo ""
fi

if [[ "${1:-all}" == "ios" || "${1:-all}" == "all" ]]; then
  echo "==> Building iOS IPA (App Store)..."
  flutter build ipa --release --export-options-plist=ios/ExportOptions.plist
  echo "    → build/ios/ipa/*.ipa"
  echo ""
fi

echo "✅ Terminé. Consultez STORE_RELEASE.md pour la soumission aux stores."
