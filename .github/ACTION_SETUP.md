# GitHub Actions Setup Guide

## Two workflows, run in order

### Workflow 1 — `build_deps.yml` (run ONCE, or when deps change)
**What it does:**
1. Installs Android NDK 27 on the GitHub runner
2. Cross-compiles **SQLCipher v4.5.7** for `arm64-v8a`, `armeabi-v7a`, `x86_64`
3. Cross-compiles **Argon2** for all 3 ABIs
4. Copies **fmtlib** headers (no compile needed — header-only)
5. **Commits** the `.a` files directly back into `src/cpp/third_party/`
6. Also uploads them as a downloadable workflow artifact

**How to run:**
> GitHub → Actions → "Build Native Dependencies" → Run workflow → Run workflow

Expected time: ~8–12 minutes

---

### Workflow 2 — `build_apk.yml` (runs on every push to main)
**What it does:**
1. Checks that the `.a` files exist (fails fast with a clear message if you forgot step 1)
2. Runs `flutter pub get`
3. Builds split APKs (`arm64-v8a`, `armeabi-v7a`, `x86_64`) + universal APK
4. Uploads all APKs as a downloadable artifact (kept 60 days)
5. If you push a tag like `v1.0.0` → auto-creates a GitHub Release with the APKs attached

---

## Optional: Release signing

If you want a signed APK (required for Play Store), add these **Repository Secrets**
under `Settings → Secrets and variables → Actions`:

| Secret name       | Value |
|---|---|
| `KEYSTORE_BASE64` | `base64 -w0 your-keystore.jks` output |
| `KEY_STORE_PASS`  | keystore password |
| `KEY_ALIAS`       | key alias |
| `KEY_PASS`        | key password |

If these secrets are absent, the workflow uses the debug key automatically
(fine for testing, not for Play Store).

---

## First-time repo setup

```bash
git clone https://github.com/YOUR_USERNAME/Cobe.git
cd Cobe
git add .
git commit -m "feat: initial Cobe project"
git push origin main

# Then in GitHub UI:
# Actions → Build Native Dependencies → Run workflow
# Wait ~10 min → it commits the .a files back
# Then every subsequent push triggers the APK build automatically
```

## Third-party directory after workflow 1 completes

```
src/cpp/third_party/
├── sqlcipher/
│   ├── include/sqlite3.h
│   ├── arm64-v8a/libsqlcipher.a     (~3.2 MB)
│   ├── armeabi-v7a/libsqlcipher.a   (~2.8 MB)
│   └── x86_64/libsqlcipher.a        (~3.4 MB)
├── argon2/
│   ├── include/argon2.h
│   ├── arm64-v8a/libargon2.a        (~180 KB)
│   ├── armeabi-v7a/libargon2.a      (~160 KB)
│   └── x86_64/libargon2.a           (~190 KB)
└── fmt/
    └── include/fmt/                  (headers only)
```
