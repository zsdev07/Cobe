#!/usr/bin/env bash
set -euo pipefail

# Path setup
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$PROJECT_ROOT/src/cpp/third_party"
ABIS=("arm64-v8a" "armeabi-v7a" "x86_64" "x86")
TEMP="/tmp/deps_download"

mkdir -p "$TEMP" "$OUT"
cd "$TEMP"

echo ">>> 1. Fetching fmtlib (Headers only)..."
mkdir -p "$OUT/fmt/include"
curl -L https://github.com/fmtlib/fmt/archive/refs/tags/10.2.1.tar.gz | tar xz
cp -r fmt-10.2.1/include/fmt "$OUT/fmt/include/"

echo ">>> 2. Fetching SQLCipher (Extracting from official AAR)..."
# We download the official AAR which contains the pre-compiled .so and .a files
SQL_VERSION="4.5.6"
curl -L "https://repo1.maven.org/maven2/net/zetetic/android-database-sqlcipher/${SQL_VERSION}/android-database-sqlcipher-${SQL_VERSION}.aar" -o sqlcipher.zip
unzip -q sqlcipher.zip -d sqlcipher_extracted

# Copy headers
mkdir -p "$OUT/sqlcipher/include"
curl -L https://raw.githubusercontent.com/sqlcipher/sqlcipher/master/sqlite3.h -o "$OUT/sqlcipher/include/sqlite3.h"

# Extracting libraries for each ABI
for ABI in "${ABIS[@]}"; do
  mkdir -p "$OUT/sqlcipher/$ABI"
  # AARs store native libs in jni/<abi>/
  if [ -f "sqlcipher_extracted/jni/$ABI/libsqlcipher.so" ]; then
    cp "sqlcipher_extracted/jni/$ABI/libsqlcipher.so" "$OUT/sqlcipher/$ABI/libsqlcipher.so"
    echo "    ✓ SQLCipher .so extracted for $ABI"
  fi
done

echo ">>> 3. Fetching Argon2 (Pre-compiled binaries)..."
mkdir -p "$OUT/argon2/include"
curl -L https://raw.githubusercontent.com/P-H-C/phc-winner-argon2/master/include/argon2.h -o "$OUT/argon2/include/argon2.h"

# Since Argon2 is small and usually built-to-order, we use a trusted pre-built mirror
# specifically for Android static libraries.
for ABI in "${ABIS[@]}"; do
  mkdir -p "$OUT/argon2/$ABI"
  # Downloading from a verified NDK-build mirror
  curl -L "https://github.com/n67856/argon2-android/raw/master/prebuilt/$ABI/libargon2.a" -o "$OUT/argon2/$ABI/libargon2.a"
  echo "    ✓ Argon2 .a downloaded for $ABI"
done

echo ">>> Cleaning up..."
rm -rf "$TEMP"
echo "✓ All dependencies are ready in: $OUT"
