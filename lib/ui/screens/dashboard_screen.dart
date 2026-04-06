import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/state/app_state.dart';
import '../components/cobe_button.dart';
import '../components/cobe_surface.dart';
import '../theme/cobe_tokens.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(projectsProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(CobeSpacing.md, CobeSpacing.md, CobeSpacing.md, 86),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _TopRow(),
          const SizedBox(height: CobeSpacing.md),
          const _GlobalSearch(),
          const SizedBox(height: CobeSpacing.md),
          Row(
            children: [
              CobeButton(label: 'Start Chat', icon: Icons.chat_bubble_outline_rounded, onPressed: () {}),
              const SizedBox(width: CobeSpacing.sm),
              CobeButton(label: 'New Project', icon: Icons.add_rounded, onPressed: () {}, isGhost: true),
            ],
          ),
          const SizedBox(height: CobeSpacing.md),
          const Text('Projects', style: TextStyle(fontSize: 13, color: CobeTokens.dark.textMuted)),
          const SizedBox(height: CobeSpacing.sm),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cols = constraints.maxWidth < 360 ? 2 : 3;
                return GridView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: projects.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    crossAxisSpacing: CobeSpacing.sm,
                    mainAxisSpacing: CobeSpacing.sm,
                    childAspectRatio: 1.18,
                  ),
                  itemBuilder: (context, i) {
                    final project = projects[i];
                    return CobeSurface(
                      padding: const EdgeInsets.all(CobeSpacing.sm),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.folder_open_rounded, size: 18, color: CobeTokens.dark.textPrimary),
                          const Spacer(),
                          Text(
                            project.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            project.path,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 10.5, color: CobeTokens.dark.textMuted),
                          ),
                        ],
                      ),
                    );
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

class _TopRow extends StatelessWidget {
  const _TopRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: Text(
            'Cobe',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: CobeTokens.dark.textPrimary),
          ),
        ),
        Text('Mobile-First Vibe Coding', style: TextStyle(fontSize: 10.5, color: CobeTokens.dark.textMuted)),
      ],
    );
  }
}

class _GlobalSearch extends StatelessWidget {
  const _GlobalSearch();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: CobeSpacing.sm),
      decoration: BoxDecoration(
        color: CobeTokens.dark.bgPanel,
        border: Border.all(color: CobeTokens.dark.border),
        borderRadius: CobeRadius.md,
      ),
      child: const Row(
        children: [
          Icon(Icons.search_rounded, size: 18, color: CobeTokens.dark.textMuted),
          SizedBox(width: CobeSpacing.xs),
          Expanded(
            child: TextField(
              style: TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search projects, files, chats',
                hintStyle: TextStyle(fontSize: 12, color: CobeTokens.dark.textMuted),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
