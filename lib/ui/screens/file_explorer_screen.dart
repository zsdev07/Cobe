// file_explorer_screen.dart — Scoped storage file browser
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/providers/providers.dart';
import '../theme/cobe_theme.dart';
import '../widgets/glass_widgets.dart';

final _currentDirProvider = StateProvider<String>((ref) => '');
final _dirEntriesProvider =
    StateProvider<List<_FsEntry>>((ref) => []);

class FileExplorerScreen extends ConsumerStatefulWidget {
  const FileExplorerScreen({super.key});
  @override
  ConsumerState<FileExplorerScreen> createState() => _FileExplorerState();
}

class _FileExplorerState extends ConsumerState<FileExplorerScreen> {
  static const _codeExts = {
    '.dart', '.cpp', '.h', '.hpp', '.c', '.py', '.js', '.ts',
    '.kt', '.java', '.rs', '.go', '.md', '.txt', '.json', '.yaml',
    '.xml', '.gradle', '.kts', '.sh', '.toml', '.lock',
  };

  Future<void> _pickFolder() async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result == null) return;
    ref.read(_currentDirProvider.notifier).state = result;
    _loadDir(result);
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.any,
    );
    if (result == null || result.files.isEmpty) return;
    final path = result.files.first.path;
    if (path != null) {
      await ref.read(fileEditorProvider.notifier).openFile(path);
      if (mounted) Navigator.pop(context);
    }
  }

  void _loadDir(String path) {
    // Delegate to FFI for scoped storage read
    // For now enumerate via dart:io
    try {
      final dir = Directory(path);
      final entries = dir.listSync(followLinks: false)
        ..sort((a, b) {
          final aIsDir = a is Directory;
          final bIsDir = b is Directory;
          if (aIsDir != bIsDir) return aIsDir ? -1 : 1;
          return a.path.compareTo(b.path);
        });
      ref.read(_dirEntriesProvider.notifier).state = entries
          .map((e) => _FsEntry(
                name: e.path.split('/').last,
                path: e.path,
                isDir: e is Directory,
                ext: e is File ? _ext(e.path) : '',
              ))
          .toList();
    } catch (_) {
      ref.read(_dirEntriesProvider.notifier).state = [];
    }
  }

  String _ext(String path) {
    final dot = path.lastIndexOf('.');
    return dot >= 0 ? path.substring(dot).toLowerCase() : '';
  }

  Color _extColor(String ext) {
    const map = {
      '.dart':  Color(0xFF54C5F8),
      '.cpp':   Color(0xFF6366F1),
      '.h':     Color(0xFF8B5CF6),
      '.py':    Color(0xFFF59E0B),
      '.js':    Color(0xFFFBBF24),
      '.ts':    Color(0xFF3B82F6),
      '.kt':    Color(0xFFEC4899),
      '.md':    Color(0xFF6EE7B7),
      '.json':  Color(0xFF34D399),
      '.yaml':  Color(0xFFFCA5A5),
    };
    return map[ext] ?? CobeColors.textSub;
  }

  IconData _icon(String ext, bool isDir) {
    if (isDir) return Icons.folder_rounded;
    if (_codeExts.contains(ext)) return Icons.code_rounded;
    return Icons.insert_drive_file_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final currentDir = ref.watch(_currentDirProvider);
    final entries    = ref.watch(_dirEntriesProvider);

    return Scaffold(
      backgroundColor: CobeColors.bg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF060810),
        title: Text('Files', style: CobeTextStyles.ui),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded,
              size: 16, color: CobeColors.textSub),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.folder_open_rounded,
                size: 18, color: CobeColors.accent),
            onPressed: _pickFolder,
            tooltip: 'Open Folder',
          ),
          IconButton(
            icon: Icon(Icons.insert_drive_file_outlined,
                size: 18, color: CobeColors.accent),
            onPressed: _pickFile,
            tooltip: 'Open File',
          ),
        ],
      ),
      body: currentDir.isEmpty
          ? _EmptyPicker(onPickFolder: _pickFolder, onPickFile: _pickFile)
          : Column(
              children: [
                // Breadcrumb
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  color: const Color(0xFF060810),
                  child: Row(
                    children: [
                      Icon(Icons.folder_open_rounded,
                          size: 12, color: CobeColors.textSub),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          currentDir,
                          style: CobeTextStyles.uiSub,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                // File list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: entries.length,
                    itemBuilder: (_, i) {
                      final e = entries[i];
                      return _FileRow(
                        entry: e,
                        iconColor: e.isDir
                            ? CobeColors.warning
                            : _extColor(e.ext),
                        icon: _icon(e.ext, e.isDir),
                        onTap: () {
                          if (e.isDir) {
                            ref.read(_currentDirProvider.notifier).state =
                                e.path;
                            _loadDir(e.path);
                          } else if (_codeExts.contains(e.ext)) {
                            ref
                                .read(fileEditorProvider.notifier)
                                .openFile(e.path);
                            Navigator.pop(context);
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _FsEntry {
  final String name, path, ext;
  final bool isDir;
  const _FsEntry(
      {required this.name,
       required this.path,
       required this.isDir,
       required this.ext});
}

class _FileRow extends StatelessWidget {
  final _FsEntry entry;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _FileRow({
    required this.entry,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: CobeColors.pulse.withOpacity(0.08),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        child: Row(
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                entry.name,
                style: CobeTextStyles.mono.copyWith(fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!entry.isDir && entry.ext.isNotEmpty)
              Text(entry.ext,
                  style: CobeTextStyles.uiSub
                      .copyWith(color: iconColor.withOpacity(0.6))),
          ],
        ),
      ),
    );
  }
}

class _EmptyPicker extends StatelessWidget {
  final VoidCallback onPickFolder, onPickFile;
  const _EmptyPicker(
      {required this.onPickFolder, required this.onPickFile});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GlassPanel(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_open_rounded,
                size: 36, color: CobeColors.textSub),
            const SizedBox(height: 12),
            Text('No folder open', style: CobeTextStyles.ui),
            const SizedBox(height: 4),
            Text('Open a project folder or single file',
                style: CobeTextStyles.uiSub),
            const SizedBox(height: 20),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Btn(
                    label: 'Open Folder',
                    icon: Icons.folder_open_rounded,
                    onTap: onPickFolder),
                const SizedBox(width: 10),
                _Btn(
                    label: 'Open File',
                    icon: Icons.insert_drive_file_outlined,
                    onTap: onPickFile),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _Btn({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: CobeColors.pulse.withOpacity(0.15),
          border: Border.all(
              color: CobeColors.pulse.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: CobeColors.pulse),
            const SizedBox(width: 6),
            Text(label,
                style: CobeTextStyles.uiSub
                    .copyWith(color: CobeColors.pulse)),
          ],
        ),
      ),
    );
  }
}
