# Third-Party Native Libraries

Place pre-built static libraries here before running `flutter build apk`.

## Directory Layout

```
third_party/
├── sqlcipher/
│   ├── include/
│   │   └── sqlite3.h          ← SQLCipher amalgamation header
│   ├── arm64-v8a/
│   │   └── libsqlcipher.a
│   ├── armeabi-v7a/
│   │   └── libsqlcipher.a
│   └── x86_64/
│       └── libsqlcipher.a
├── argon2/
│   ├── include/
│   │   └── argon2.h
│   ├── arm64-v8a/
│   │   └── libargon2.a
│   ├── armeabi-v7a/
│   │   └── libargon2.a
│   └── x86_64/
│       └── libargon2.a
└── fmt/
    └── include/
        └── fmt/               ← fmtlib headers (header-only, no .a needed)
            ├── core.h
            ├── format.h
            └── ...
```

## Build Instructions

### SQLCipher for Android
```bash
git clone https://github.com/sqlcipher/sqlcipher
cd sqlcipher
# Cross-compile for each ABI using Android NDK toolchain
# See: https://www.zetetic.net/sqlcipher/open-source/
```

### Argon2 for Android
```bash
git clone https://github.com/P-H-C/phc-winner-argon2
cd phc-winner-argon2
# Cross-compile for each ABI using Android NDK
```

### fmtlib (header-only)
```bash
git clone https://github.com/fmtlib/fmt
cp -r fmt/include/fmt third_party/fmt/include/
```

## Quick Docker Build (recommended)
```bash
docker run --rm -v $(pwd):/work ghcr.io/android-ndk/android-ndk:r27 \
  bash /work/scripts/build_deps.sh
```
