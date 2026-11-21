import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../state/app_controller.dart';
import '../widgets/adaptive_shell.dart';

/// 16 — Merged: the merge snapshot landed. The left-behind card is as big
/// as the success card — restraint is a feature.
class MergedScreen extends StatelessWidget {
  const MergedScreen({
    required this.branchId,
    required this.snapshotId,
    required this.sourceId,
    super.key,
  });

  final String branchId;
  final String snapshotId;
  final String sourceId;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final project = controller.openProject;
    final branch = project?.branchById(branchId);
    final source = project?.branchById(sourceId);
    final snapshot = branch?.snapshots
        .where((s) => s.id == snapshotId)
        .toList();
    if (project == null || branch == null || snapshot == null ||
        snapshot.isEmpty) {
      return const AdaptiveScaffold(
        title: 'Merged',
        tab: 1,
        body: Center(child: Text('Snapshot not found.')),
      );
    }
    final snap = snapshot.first;
    final leftBehind = controller.lastMergeLeftBehind;
    final applied = snap.changes.length;

    return AdaptiveScaffold(
      title: 'Merged',
      subtitle: '${snap.id} · ${branch.name}',
      tab: 1,
      body: ScreenBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            const Icon(
              Icons.merge,
              size: 56,
              color: ParallelPalette.cutRed,
            ),
            const SizedBox(height: 16),
            Text(
              '${source?.name ?? 'The branch'} is part\nof ${branch.name} now',
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$applied change${applied == 1 ? '' : 's'} landed. '
              '${branch.name} runs '
              '${formatDuration(branch.runtimeSeconds)}.',
              style: const TextStyle(
                fontSize: 15,
                color: ParallelPalette.secondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${snap.id} · ${snap.author} · '
                      '${formatRelative(snap.createdAt)} · merge of '
                      '${snap.mergeOf}',
                      style: AppTheme.mono(
                        size: 12,
                        color: ParallelPalette.muted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      snap.message,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$applied changes · '
                      '${leftBehind.length} left on ${source?.name ?? 'the source'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: ParallelPalette.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (leftBehind.isNotEmpty) ...[
              const SizedBox(height: 12),
              Card(
                color: ParallelPalette.paper2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Left behind, on purpose',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      for (final change in leftBehind)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '· ${change.title}: ${change.detail}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: ParallelPalette.secondary,
                              height: 1.5,
                            ),
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        'Merge them later, or leave ${source?.name ?? 'the branch'} '
                        'as the longer cut.',
                        style: const TextStyle(
                          fontSize: 14,
                          color: ParallelPalette.secondary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    Routes.branchDetail,
                    arguments: BranchArgs(branch.id),
                  );
                },
                child: const Text('See the merged branch'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
