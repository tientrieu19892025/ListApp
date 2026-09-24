#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")/.."
export THEOS="${THEOS:-$HOME/theos}"

TOOLCHAIN="${TOOLCHAIN:-/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin}"
export TARGET_CC="${TARGET_CC:-$TOOLCHAIN/clang}"
export TARGET_CXX="${TARGET_CXX:-$TOOLCHAIN/clang++}"
export TARGET_LD="${TARGET_LD:-$TARGET_CC}"
export TARGET_STRIP="${TARGET_STRIP:-$TOOLCHAIN/strip}"
export TARGET_LIPO="${TARGET_LIPO:-$TOOLCHAIN/lipo}"
export TARGET_CODESIGN_ALLOCATE="${TARGET_CODESIGN_ALLOCATE:-$TOOLCHAIN/codesign_allocate}"

# Detect available make binary
if ! /usr/bin/make --version >/dev/null 2>&1; then
  if [[ -x /Library/Developer/CommandLineTools/usr/bin/make ]]; then
    export PATH="/Library/Developer/CommandLineTools/usr/bin:$PATH"
  fi
fi
MAKEBIN="$(command -v gmake 2>/dev/null || command -v make)"

echo "════════════════════════════════════════"
echo "  Building ListApp — 3 Schemes"
echo "════════════════════════════════════════"

echo ""
echo "--> 1. Building Rootful (iphoneos-arm)..."
"$MAKEBIN" clean
"$MAKEBIN" package FINALPACKAGE=1

echo ""
echo "--> 2. Building Rootless (iphoneos-arm64)..."
"$MAKEBIN" clean
"$MAKEBIN" package FINALPACKAGE=1 THEOS_PACKAGE_SCHEME=rootless

echo ""
echo "--> 3. Building RootHide (iphoneos-arm64e)..."
if [[ -d "$HOME/theos-roothide" ]]; then
  echo "RootHide Theos detected at $HOME/theos-roothide"
  THEOS="$HOME/theos-roothide" "$MAKEBIN" clean
  THEOS="$HOME/theos-roothide" "$MAKEBIN" package FINALPACKAGE=1 THEOS_PACKAGE_SCHEME=roothide || {
    echo "RootHide build skipped or completed with warnings."
  }
else
  "$MAKEBIN" clean
  "$MAKEBIN" package FINALPACKAGE=1 THEOS_PACKAGE_SCHEME=roothide || echo "RootHide scheme unavailable on this Theos."
fi

echo ""
echo "════════════════════════════════════════"
echo "  Build Completed! Generated Packages:"
echo "════════════════════════════════════════"
ls -lh packages/ || true
