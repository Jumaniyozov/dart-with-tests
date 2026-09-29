#!/bin/sh
# Builds dart-generate-<version>.vsix for macOS arm64: the helper binary, the
# bundle, the package, and a check that the helper keeps its executable bit.
set -eu
cd "$(dirname "$0")/.."

# dart compile exe builds for this machine, and the package says darwin-arm64.
arch=$(uname -m)
if [ "$arch" != "arm64" ]; then
  echo "The package is for darwin-arm64, so build it on arm64, not $arch." >&2
  exit 1
fi

mkdir -p bin
dart compile exe ../helper/bin/helper.dart -o bin/helper
npm run compile

version=$(node -p "require('./package.json').version")
vsix="dart-generate-$version.vsix"
# esbuild bundles every dependency, so vsce needs no npm dependency scan.
npx vsce package --target darwin-arm64 --no-dependencies --skip-license \
  --allow-missing-repository --out "$vsix"

# Without the executable bit, the installed helper cannot start.
mode=$(unzip -Z "$vsix" extension/bin/helper | cut -c1-10)
if [ "$mode" != "-rwxr-xr-x" ]; then
  echo "extension/bin/helper has mode $mode, not -rwxr-xr-x" >&2
  exit 1
fi

echo "Install with: code --install-extension $PWD/$vsix"
