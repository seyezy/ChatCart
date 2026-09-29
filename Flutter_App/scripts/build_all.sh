#!/usr/bin/env bash
set -euo pipefail
flutter pub get
for flavor in development staging production; do
  flutter build apk --flavor "$flavor" --release
  flutter build appbundle --flavor "$flavor" --release
done
