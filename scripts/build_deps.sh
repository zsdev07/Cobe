#!/usr/bin/env bash
# scripts/build_deps.sh — Cross-compile SQLCipher + Argon2 for Android ABIs
# Requires: Android NDK r27+ in $ANDROID_NDK_HOME
set -euo pipefail

NDK="${ANDROID_NDK_HOME:-$HOME/Android/Sdk/ndk/27.0.12077973}"
ABIS=("arm64-v8a" "armeabi-v7a" "x86_64")
# Get the absolute path to the project root
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$PROJECT_ROOT/src/cpp/third_party"
WORK="/tmp/cobe_deps"


mkdir -p "$WORK" && cd "$WORK"

# ── Toolchain helper ───────────────────────────────────────────────────────
get_triple() {
  case "$1" in
    arm64-v8a)   echo "aarch64-linux-android"   ;;
    armeabi-v7a) echo "armv7a-linux-androideabi" ;;
    x86_64)      echo "x86_64-linux-android"     ;;
  esac
}

get_api() { echo "26"; }

# ── fmtlib (header-only, no compile needed) ────────────────────────────────
echo ">>> Fetching fmtlib headers"
if [ ! -d fmt ]; then
  git clone --depth 1 --branch 10.2.1 https://github.com/fmtlib/fmt.git
fi
mkdir -p "$OUT/fmt/include"
cp -r fmt/include/fmt "$OUT/fmt/include/"
echo "    fmtlib headers installed"

# ── Argon2 ─────────────────────────────────────────────────────────────────
echo ">>> Building Argon2"
if [ ! -d argon2 ]; then
  git clone --depth 1 https://github.com/P-H-C/phc-winner-argon2.git argon2
fi

mkdir -p "$OUT/argon2/include"
cp argon2/include/argon2.h "$OUT/argon2/include/"

for ABI in "${ABIS[@]}"; do
  TRIPLE=$(get_triple "$ABI")
  API=$(get_api)
  TOOLCHAIN="$NDK/toolchains/llvm/prebuilt/linux-x86_64"
  CC="$TOOLCHAIN/bin/${TRIPLE}${API}-clang"

  mkdir -p "$OUT/argon2/$ABI"
  cd argon2
  make clean 2>/dev/null || true
  CFLAGS="-O3 -fPIC" CC="$CC" make libargon2.a \
    ARGON2_NAME=argon2 \
    2>/dev/null
  cp libargon2.a "$OUT/argon2/$ABI/"
  cd ..
  echo "    Argon2 built for $ABI"
done

# ── SQLCipher ─────────────────────────────────────────────────────────────
echo ">>> Building SQLCipher"
if [ ! -d sqlcipher ]; then
  git clone --depth 1 --branch v4.5.6 https://github.com/sqlcipher/sqlcipher.git
fi

# Create include dir
mkdir -p "$OUT/sqlcipher/include"

for ABI in "${ABIS[@]}"; do
  TRIPLE=$(get_triple "$ABI")
  API=$(get_api)
  TOOLCHAIN="$NDK/toolchains/llvm/prebuilt/linux-x86_64"
  
  # Explicitly define the full toolchain
  export CC="$TOOLCHAIN/bin/${TRIPLE}${API}-clang"
  export AR="$TOOLCHAIN/bin/llvm-ar"
  export AS="$TOOLCHAIN/bin/${TRIPLE}${API}-clang"
  export RANLIB="$TOOLCHAIN/bin/llvm-ranlib"
  export STRIP="$TOOLCHAIN/bin/llvm-strip"

  mkdir -p "$OUT/sqlcipher/$ABI"
  cd sqlcipher
  
  echo "    Cleaning $ABI..."
  make clean > /dev/null 2>&1 || true
  
  echo "    Configuring $ABI..."
  ./configure \
    --host="${TRIPLE}" \
    --with-pic \
    --disable-tcl \
    --disable-shared \
    --enable-static \
    --enable-tempstore=yes \
    --with-crypto-lib=none \
    CFLAGS="-DSQLITE_HAS_CODEC -DSQLITE_TEMP_STORE=2 -O3 -fPIC" \
    LDFLAGS="-lm"

  echo "    Compiling $ABI..."
  # Removed 2>/dev/null so we can see errors if it fails
  make libsqlcipher.a -j$(nproc)

  cp .libs/libsqlcipher.a "$OUT/sqlcipher/$ABI/" 2>/dev/null || \
    cp libsqlcipher.a "$OUT/sqlcipher/$ABI/" 2>/dev/null || true
    
  cp sqlite3.h "$OUT/sqlcipher/include/" 2>/dev/null || true
  
  cd ..
  echo "    ✓ SQLCipher built for $ABI"
done



echo ""
echo "✓ All dependencies built at: $OUT"
echo ""
echo "Next steps:"
echo "  cd <project_root>"
echo "  flutter pub get"
echo "  flutter build apk --release"
