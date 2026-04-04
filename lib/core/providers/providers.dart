// providers.dart — Riverpod state providers for Cobe
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../ffi/ffi_bridge.dart';

// ── Engine Status ─────────────────────────────────────────────────────────
final engineStatusProvider = StreamProvider<String>((ref) {
  return ffi.statusStream;
});

// ── Indexing State ────────────────────────────────────────────────────────
class IndexingState {
  final bool active;
  final String currentFile;
  const IndexingState({this.active = false, this.currentFile = ''});
  IndexingState copyWith({bool? active, String? currentFile}) =>
      IndexingState(
          active: active ?? this.active,
          currentFile: currentFile ?? this.currentFile);
}

class IndexingNotifier extends Notifier<IndexingState> {
  StreamSubscription<String>? _sub;

  @override
  IndexingState build() {
    _sub = ffi.statusStream.listen((msg) {
      if (msg.startsWith('INDEXING:')) {
        state = IndexingState(active: true, currentFile: msg.substring(9));
      } else if (msg == 'IDLE_SAVE' || msg == 'AUTO_SAVE') {
        state = const IndexingState(active: false);
      }
    });
    ref.onDispose(() => _sub?.cancel());
    return const IndexingState();
  }
}

final indexingProvider = NotifierProvider<IndexingNotifier, IndexingState>(
    IndexingNotifier.new);

// ── Active File ────────────────────────────────────────────────────────────
class FileEditorState {
  final String path;
  final String content;
  final bool dirty;
  const FileEditorState({this.path = '', this.content = '', this.dirty = false});
  FileEditorState copyWith({String? path, String? content, bool? dirty}) =>
      FileEditorState(
          path: path ?? this.path,
          content: content ?? this.content,
          dirty: dirty ?? this.dirty);
}

class FileEditorNotifier extends Notifier<FileEditorState> {
  @override
  FileEditorState build() => const FileEditorState();

  Future<void> openFile(String path) async {
    final content = await ffi.readFile(path);
    state = FileEditorState(path: path, content: content, dirty: false);
  }

  void edit(String newContent) {
    ffi.poke();
    state = state.copyWith(content: newContent, dirty: true);
  }

  void save() {
    if (state.path.isNotEmpty && state.dirty) {
      ffi.writeFile(state.path, state.content);
      state = state.copyWith(dirty: false);
    }
  }
}

final fileEditorProvider =
    NotifierProvider<FileEditorNotifier, FileEditorState>(FileEditorNotifier.new);

// ── AI Request ────────────────────────────────────────────────────────────
enum AiStatus { idle, thinking, done, error }

class AiState {
  final AiStatus status;
  final String response;
  final String ghostText;
  const AiState(
      {this.status = AiStatus.idle, this.response = '', this.ghostText = ''});
  AiState copyWith({AiStatus? status, String? response, String? ghostText}) =>
      AiState(
          status: status ?? this.status,
          response: response ?? this.response,
          ghostText: ghostText ?? this.ghostText);
}

class AiNotifier extends Notifier<AiState> {
  @override
  AiState build() => const AiState();

  Future<void> ask({required String prompt, String system = '', int provider = 0}) async {
    state = const AiState(status: AiStatus.thinking);
    try {
      final ctx = await ffi.queryContext(prompt, topK: 5);
      final enriched = '[Context: $ctx]\n\n$prompt';
      final r = await ffi.request(prompt: enriched, system: system, provider: provider);
      state = AiState(status: AiStatus.done, response: r);
    } catch (e) {
      state = AiState(status: AiStatus.error, response: e.toString());
    }
  }

  Future<void> ghostSuggest(String lineContext) async {
    try {
      final r = await ffi.request(
          prompt: 'Complete this code (one line only): $lineContext',
          provider: 1); // GroqSmall for low-latency ghost text
      state = state.copyWith(ghostText: r);
    } catch (_) {
      state = state.copyWith(ghostText: '');
    }
  }

  void clearGhost() => state = state.copyWith(ghostText: '');
}

final aiProvider = NotifierProvider<AiNotifier, AiState>(AiNotifier.new);

// ── Provider Settings ─────────────────────────────────────────────────────
class ProviderConfig {
  final Map<int, String> keys; // provider index → masked key
  const ProviderConfig({this.keys = const {}});
  ProviderConfig withKey(int p, String k) =>
      ProviderConfig(keys: {...keys, p: k});
}

class ProviderConfigNotifier extends Notifier<ProviderConfig> {
  @override
  ProviderConfig build() => const ProviderConfig();

  void setKey(int provider, String rawKey) {
    ffi.setProviderKey(provider, rawKey);
    // Store masked indicator only (never persist raw key)
    state = state.withKey(provider, '•' * rawKey.length);
  }
}

final providerConfigProvider =
    NotifierProvider<ProviderConfigNotifier, ProviderConfig>(
        ProviderConfigNotifier.new);

// ── Panic State ────────────────────────────────────────────────────────────
final panicProvider = StateProvider<bool>((ref) => false);

void triggerPanic(WidgetRef ref) {
  ffi.panic();
  ref.read(panicProvider.notifier).state = true;
  Future.delayed(const Duration(seconds: 3),
      () => ref.read(panicProvider.notifier).state = false);
}

// ── Diff Artifacts ────────────────────────────────────────────────────────
class DiffArtifact {
  final String fileName;
  final String original;
  final String proposed;
  const DiffArtifact(
      {required this.fileName, required this.original, required this.proposed});
}

class ArtifactsNotifier extends Notifier<List<DiffArtifact>> {
  @override
  List<DiffArtifact> build() => [];

  void add(DiffArtifact a) => state = [...state, a];
  void remove(int i) => state = [...state]..removeAt(i);
  void clear() => state = [];

  void apply(int i) {
    final a = state[i];
    ffi.writeFile(a.fileName, a.proposed);
    remove(i);
  }
}

final artifactsProvider =
    NotifierProvider<ArtifactsNotifier, List<DiffArtifact>>(
        ArtifactsNotifier.new);

// ── Hover Menu ─────────────────────────────────────────────────────────────
class HoverMenuState {
  final bool visible;
  final double x, y;
  final bool circular; // false = horizontal
  const HoverMenuState(
      {this.visible = false, this.x = 40, this.y = 200, this.circular = true});
  HoverMenuState copyWith(
          {bool? visible, double? x, double? y, bool? circular}) =>
      HoverMenuState(
          visible: visible ?? this.visible,
          x: x ?? this.x,
          y: y ?? this.y,
          circular: circular ?? this.circular);
}

final hoverMenuProvider =
    NotifierProvider<HoverMenuNotifier, HoverMenuState>(HoverMenuNotifier.new);

class HoverMenuNotifier extends Notifier<HoverMenuState> {
  @override
  HoverMenuState build() => const HoverMenuState();

  void toggle() => state = state.copyWith(visible: !state.visible);
  void move(double x, double y) => state = state.copyWith(x: x, y: y);
  void setStyle(bool circular) => state = state.copyWith(circular: circular);
}
