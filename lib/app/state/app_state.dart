import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProjectInfo {
  const ProjectInfo({required this.id, required this.name, required this.path});

  final String id;
  final String name;
  final String path;
}

class ChatMessage {
  const ChatMessage({
    required this.role,
    required this.text,
    required this.provider,
    required this.model,
    this.isStreaming = false,
  });

  final String role;
  final String text;
  final String provider;
  final String model;
  final bool isStreaming;

  ChatMessage copyWith({String? text, bool? isStreaming}) {
    return ChatMessage(
      role: role,
      text: text ?? this.text,
      provider: provider,
      model: model,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }
}

final projectsProvider = Provider<List<ProjectInfo>>((ref) {
  return const [
    ProjectInfo(id: 'p1', name: 'Cobe App', path: '/storage/emulated/0/Cobe/app'),
    ProjectInfo(id: 'p2', name: 'Agent Runtime', path: '/storage/emulated/0/Cobe/runtime'),
    ProjectInfo(id: 'p3', name: 'Widget Kit', path: '/storage/emulated/0/Cobe/ui-kit'),
  ];
});

final activeProjectIdProvider = StateProvider<String>((ref) => 'p1');

final draftProvider = StateProvider<String>((ref) => 'Generate a mobile-first dashboard shell.');

class ChatController extends StateNotifier<List<ChatMessage>> {
  ChatController()
      : super(const [
          ChatMessage(
            role: 'assistant',
            text: 'Cobe ready. I can generate files, diff patches, and run local tasks.',
            provider: 'OpenAI',
            model: 'gpt-5.3-codex',
          ),
        ]);

  void sendUserMessage(String content) {
    if (content.trim().isEmpty) return;
    state = [
      ...state,
      ChatMessage(role: 'user', text: content.trim(), provider: 'manual', model: 'manual'),
      const ChatMessage(
        role: 'assistant',
        text: 'Streaming response initialized…',
        provider: 'OpenAI',
        model: 'gpt-5.3-codex',
        isStreaming: true,
      ),
    ];
  }

  void updateStreaming(String content) {
    if (state.isEmpty) return;
    final last = state.last;
    if (!last.isStreaming) return;
    state = [
      ...state.sublist(0, state.length - 1),
      last.copyWith(text: content, isStreaming: true),
    ];
  }

  void stopStreaming() {
    if (state.isEmpty) return;
    final last = state.last;
    if (!last.isStreaming) return;
    state = [
      ...state.sublist(0, state.length - 1),
      last.copyWith(isStreaming: false),
    ];
  }

  void regenerate() {
    if (state.isEmpty) return;
    final trimmed = [...state]..removeWhere((m) => m.role == 'assistant' && m.isStreaming);
    state = [...trimmed, const ChatMessage(role: 'assistant', text: 'Regenerating…', provider: 'OpenAI', model: 'gpt-5.3-codex', isStreaming: true)];
  }
}

final chatProvider = StateNotifierProvider<ChatController, List<ChatMessage>>((ref) => ChatController());

class ArtifactFile {
  const ArtifactFile({required this.name, required this.lines, required this.status});

  final String name;
  final int lines;
  final String status;
}

final artifactFilesProvider = Provider<List<ArtifactFile>>((ref) {
  return const [
    ArtifactFile(name: 'lib/main.dart', lines: 120, status: 'updated'),
    ArtifactFile(name: 'lib/ui/screens/chat_screen.dart', lines: 240, status: 'created'),
    ArtifactFile(name: 'lib/ui/components/floating_taskbar.dart', lines: 154, status: 'created'),
  ];
});
