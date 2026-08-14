#!/bin/bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="$ROOT/Codex Provider Switcher.xcodeproj"
SCHEME="Codex Provider Switcher"
CONFIGURATION="Release"
WORK="$ROOT/.build-app"
DERIVED="$WORK/DerivedData"
DIST="$ROOT/dist"
LOG="$WORK/build.log"

mkdir -p "$WORK" "$DIST"
: > "$LOG"
exec > >(tee -a "$LOG") 2>&1

on_error() {
  echo
  echo "Build failed. See: $LOG"
}
trap on_error ERR

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "Error: this script must run on macOS."
  exit 1
fi

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "Error: xcodebuild was not found. Install the full Xcode application."
  exit 1
fi

DEVELOPER_DIR="$(xcode-select -p 2>/dev/null || true)"
if [[ -z "$DEVELOPER_DIR" ]]; then
  echo "Error: no active Xcode developer directory was found."
  exit 1
fi
if [[ "$DEVELOPER_DIR" == *"CommandLineTools"* ]]; then
  echo "Error: Xcode Command Line Tools are selected, but this project requires the full Xcode app."
  echo "Open Xcode once, then run:"
  echo "  sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
  exit 1
fi

if [[ ! -d "$PROJECT" ]]; then
  echo "Error: Xcode project not found: $PROJECT"
  exit 1
fi

xcodebuild -version

echo
echo "Running core tests..."
swift test --package-path "$ROOT"

echo
echo "Building universal macOS app..."
rm -rf "$DERIVED"
xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -derivedDataPath "$DERIVED" \
  ARCHS="arm64 x86_64" \
  ONLY_ACTIVE_ARCH=NO \
  CODE_SIGNING_ALLOWED=NO \
  build

BUILD_SETTINGS="$(xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -derivedDataPath "$DERIVED" \
  CODE_SIGNING_ALLOWED=NO \
  -showBuildSettings)"

MARKETING_VERSION="$(printf '%s\n' "$BUILD_SETTINGS" | awk -F ' = ' '/^[[:space:]]*MARKETING_VERSION = / {print $2; exit}')"
TARGET_BUILD_DIR="$(printf '%s\n' "$BUILD_SETTINGS" | awk -F ' = ' '/^[[:space:]]*TARGET_BUILD_DIR = / {print $2; exit}')"
FULL_PRODUCT_NAME="$(printf '%s\n' "$BUILD_SETTINGS" | awk -F ' = ' '/^[[:space:]]*FULL_PRODUCT_NAME = / {print $2; exit}')"
EXECUTABLE_NAME="$(printf '%s\n' "$BUILD_SETTINGS" | awk -F ' = ' '/^[[:space:]]*EXECUTABLE_NAME = / {print $2; exit}')"

if [[ -z "$MARKETING_VERSION" || -z "$TARGET_BUILD_DIR" || -z "$FULL_PRODUCT_NAME" || -z "$EXECUTABLE_NAME" ]]; then
  echo "Error: could not resolve Xcode build settings."
  exit 1
fi

SOURCE_APP="$TARGET_BUILD_DIR/$FULL_PRODUCT_NAME"
OUTPUT_APP="$DIST/$FULL_PRODUCT_NAME"
OUTPUT_ZIP="$DIST/Codex-Provider-Switcher-${MARKETING_VERSION}-macOS-universal.zip"

if [[ ! -d "$SOURCE_APP" ]]; then
  echo "Error: built application was not found at: $SOURCE_APP"
  exit 1
fi

rm -rf "$OUTPUT_APP" "$OUTPUT_ZIP"
/usr/bin/ditto "$SOURCE_APP" "$OUTPUT_APP"

BINARY="$OUTPUT_APP/Contents/MacOS/$EXECUTABLE_NAME"
if [[ ! -f "$BINARY" ]]; then
  echo "Error: app executable was not found: $BINARY"
  exit 1
fi

ARCH_LIST="$(/usr/bin/lipo -archs "$BINARY")"
echo "Built architectures: $ARCH_LIST"
if [[ "$ARCH_LIST" != *"arm64"* || "$ARCH_LIST" != *"x86_64"* ]]; then
  echo "Error: expected a universal arm64 + x86_64 application."
  exit 1
fi

/usr/bin/codesign --force --deep --sign - "$OUTPUT_APP"
/usr/bin/codesign --verify --deep --strict "$OUTPUT_APP"
/usr/bin/ditto -c -k --sequesterRsrc --keepParent "$OUTPUT_APP" "$OUTPUT_ZIP"

echo
echo "Build complete"
echo "App: $OUTPUT_APP"
echo "Zip: $OUTPUT_ZIP"
echo "Log: $LOG"
