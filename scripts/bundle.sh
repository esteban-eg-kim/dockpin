#!/usr/bin/env bash
# Builds build/dockpin.app (universal, ad-hoc signed).
#   scripts/bundle.sh                 version from the latest v* tag, else 0.0.0
#   VERSION=0.1.0 scripts/bundle.sh
#   ARCHS=arm64 scripts/bundle.sh     faster local build
#   SIGN_ID="dockpin dev" scripts/bundle.sh
#       sign with a fixed local identity so the Accessibility grant survives rebuilds
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="${VERSION:-$(git describe --tags --abbrev=0 --match 'v*' 2>/dev/null | sed 's/^v//' || true)}"
VERSION="${VERSION:-0.0.0}"
ARCHS="${ARCHS:-arm64 x86_64}"
SIGN_ID="${SIGN_ID:--}"
APP="build/dockpin.app"

# Every triple writes to the same products folder, so set each binary aside as it lands.
mkdir -p build/arch
bins=()
for arch in $ARCHS; do
  triple="$arch-apple-macosx13.0"
  swift build -c release --triple "$triple" 2>&1 | grep -vE "search path|CompatibilityPacks" || true
  bin="$(swift build -c release --triple "$triple" --show-bin-path)/dockpin"
  [ "$(lipo -archs "$bin" 2>/dev/null)" = "$arch" ] || { echo "build failed for $arch" >&2; exit 1; }
  cp "$bin" "build/arch/dockpin-$arch"
  bins+=("build/arch/dockpin-$arch")
done

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
lipo -create "${bins[@]}" -output "$APP/Contents/MacOS/dockpin"
sed "s/__VERSION__/$VERSION/g" Resources/Info.plist > "$APP/Contents/Info.plist"
cp Resources/AppIcon.icns "$APP/Contents/Resources/"
codesign --force --options runtime --sign "$SIGN_ID" "$APP"

echo "built $APP $VERSION ($(lipo -archs "$APP/Contents/MacOS/dockpin"))"
