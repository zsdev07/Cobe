#!/usr/bin/env bash
set -euo pipefail

# Path setup
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$PROJECT_ROOT/src/cpp/third_party"
ABIS=("arm64-v8a" "armeabi-v7a" "x86_64")
TEMP="/tmp/deps_download"

mkdir -p "$TEMP" "$OUT"
cd "$TEMP"

echo ">>> 1. Fetching fmtlib (Headers only)..."
mkdir -p "$OUT/fmt/include"
# Use -L to follow redirects
curl -SL https://github.com/fmtlib/fmt/archive/refs/tags/10.2.1.tar.gz | tar xz
cp -r fmt-10.2.1/include/fmt "$OUT/fmt/include/"

echo ">>> 2. Fetching SQLCipher (Official Android Binaries)..."
# Using a more direct CDN link for the AAR
SQL_VERSION="4.5.6"
SQL_URL="https://repo1.maven.org/maven2/net/zetetic/android-database-sqlcipher/${SQL_VERSION}/android-database-sqlcipher-${SQL_VERSION}.aar"

curl -SL "$SQL_URL" -o sqlcipher.aar
# Unzip the AAR (which is just a zip file)
unzip -q sqlcipher.aar -d sqlcipher_extracted

# Copy SQLCipher headers
mkdir -p "$OUT/sqlcipher/include"
curl -SL https://raw.githubusercontent.com/sqlcipher/sqlcipher/master/sqlite3.h -o "$OUT/sqlcipher/include/sqlite3.h"

for ABI in "${ABIS[@]}"; do
  mkdir -p "$OUT/sqlcipher/$ABI"
  # AAR stores native libs in the /jni/ folder
  if [ -f "sqlcipher_extracted/jni/$ABI/libsqlcipher.so" ]; then
    cp "sqlcipher_extracted/jni/$ABI/libsqlcipher.so" "$OUT/sqlcipher/$ABI/"
    echo "    ✓ SQLCipher .so extracted for $ABI"
  fi
done

echo ">>> 3. Fetching Argon2 (Pre-built Static Libs)..."
mkdir -p "$OUT/argon2/include"
curl -SL https://raw.githubusercontent.com/P-H-C/phc-winner-argon2/master/include/argon2.h -o "$OUT/argon2/include/argon2.h"

for ABI in "${ABIS[@]}"; do
  mkdir -p "$OUT/argon2/$ABI"
  # Downloading from a known-working NDK-build repository
  curl -SL "https://github.com/n67856/argon2-android/raw/master/prebuilt/$ABI/libargon2.a" -o "$OUT/argon2/$ABI/libargon2.a"
  echo "    ✓ Argon2 .a downloaded for $ABI"
done

echo ">>> Cleaning up..."
rm -rf "$TEMP"
echo "✓ Success! Files are in $OUT"
