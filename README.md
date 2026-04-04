# Cobe — AI-Powered Code Editor

**Package:** `zx.offical.cobe`  
**Stack:** Flutter 3.24+ · C++20 · Dart FFI · Riverpod  
**Aesthetic:** Midnight Black · Glassmorphism · Gaussian Blur · Glow Pulse

---

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                  Flutter UI (Riverpod)               │
│  EditorScreen · ArtifactsPanel · HoverMenu          │
│  ProviderSettings · FileExplorer · Terminal         │
└────────────────────┬────────────────────────────────┘
                     │ Dart FFI (NativeCallable)
┌────────────────────▼────────────────────────────────┐
│              ffi_bridge.dart                         │
│   Zero-copy C ↔ Dart via NativeCallable.listener    │
└────────────────────┬────────────────────────────────┘
                     │ C linkage (cobe_*)
┌────────────────────▼────────────────────────────────┐
│              C++20 Engine (libcobe_engine.so)        │
│  ThreadPool(4) · GhostSwitch · FileWatcher          │
│  VectorIndexer · AutoSave · SecureDB · SecureKey    │
└─────────────────────────────────────────────────────┘
```

## Security Model

| Layer | Mechanism |
|---|---|
| DB encryption | SQLCipher + Argon2id KDF (t=3, m=64MB) |
| API keys in RAM | XOR-masked in heap (SecureKey) |
| Panic flush | Double-tap logo → zero all XOR keys + lock SQLCipher |
| Key derivation salt | Seeded from bundle ID bytes |

## Ghost Switch Failover

```
Request → GroqLarge (70B)
    429/5xx → GroqSmall (8B)   [immediate retry]
    429/5xx → OpenAI (GPT-4o)  [retry 2]
    429/5xx → Claude            [retry 3]
    fail    → UI error callback
```

## Build Steps

### 1. Install Native Dependencies
```bash
export ANDROID_NDK_HOME=~/Android/Sdk/ndk/27.0.12077973
bash scripts/build_deps.sh
```

### 2. Get Fonts
Place JetBrains Mono + Fira Code `.ttf` files in `assets/fonts/`  
See `assets/fonts/README.md` for download links.

### 3. Flutter Build
```bash
flutter pub get
flutter build apk --release
```

## File Map

```
lib/
├── main.dart                          # Entry: FFI init + Riverpod root
├── core/
│   ├── ffi/ffi_bridge.dart            # C↔Dart NativeCallable bridge
│   └── providers/providers.dart       # All Riverpod state
└── ui/
    ├── theme/cobe_theme.dart          # Design tokens
    ├── widgets/
    │   ├── glass_widgets.dart         # GlassPanel, PulseGlow, FrostOverlay
    │   ├── hover_menu.dart            # Draggable circular/horizontal menu
    │   └── artifacts_panel.dart       # Diff view + Apply/Discard/Refine
    └── screens/
        ├── editor_screen.dart         # Main editor + ghost text + panic
        ├── provider_settings_screen.dart  # Multi-model API key hub
        ├── file_explorer_screen.dart  # Scoped storage file browser
        └── terminal_screen.dart       # PTY shell (off by default)

src/cpp/
├── engine.h                           # Public API + C-linkage exports
├── engine.cpp                         # Full C++20 Brain
├── ffi_exports.cpp                    # C shim → Engine class
├── CMakeLists.txt                     # NDK build: SQLCipher + Argon2
└── third_party/README.md              # Dep layout instructions
```
