import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../state/app_controller.dart';
import '../widgets/adaptive_shell.dart';

/// 13 — Restored: the decision is back, as a new snapshot. Nothing was
/// rewritten.
class RestoredScreen extends StatelessWidget {
  const RestoredScreen({
    required this.branchId,
    required this.snapshotId,
    super.key,
  });

  final String branchId;
  final String snapshotId;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final project = controller.openProject;
    final branch = project?.branchById(branchId);
    final snapshot = branch?.snapshots
        .where((s) => s.id == snapshotId)
        .toList();
    if (project == null || branch == null || snapshot == null ||
        snapshot.isEmpty) {
      return const AdaptiveScaffold(
        title: 'Restored',
        tab: 2,
        body: Center(child: Text('Snapshot not found.')),
      );
    }
    final snap = snapshot.first;
    final restoredId = snap.restores ?? '';
    final scene = snap.changes.isEmpty
        ? null
        : (snap.changes.first.scenes.isEmpty
            ? null
            : snap.changes.first.scenes.first);

    return AdaptiveScaffold(
      title: 'Restored',
      subtitle: '${snap.id} · ${branch.name}',
      tab: 2,
      showNav: true,
      body: ScreenBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            const _Confetti(),
            const SizedBox(height: 16),
            Text(
              'The ${snap.restorePhrase} is back',
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${snap.id} restores ${snap.restorePhrase}. '
              'Everything after $restoredId is untouched.',
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
                      '${formatRelative(snap.createdAt)} · on ${branch.name}',
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
                      'Restores $restoredId · '
                      '${snap.changes.length} decision'
                      '${snap.changes.length == 1 ? '' : 's'} · 0 conflicts',
                      style: const TextStyle(
                        fontSize: 12,
                        color: ParallelPalette.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    Routes.timeline,
                    arguments: TimelineArgs(highlightScene: scene),
                  );
                },
                child: Text(
                  scene == null
                      ? 'Open the timeline'
                      : 'See scene $scene on the timeline',
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    Routes.snapshots,
                    arguments: SnapshotsArgs(branchId: branch.id),
                  );
                },
                child: const Text('Back to snapshots'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A small static confetti burst (drawn dots — the V7 freeze-frame
/// moment, without an animation dependency).
class _Confetti extends StatelessWidget {
  const _Confetti();

  @override
  Widget build(BuildContext context) {
    const colors = [
      ParallelPalette.cutRed,
      ParallelPalette.amber,
      ParallelPalette.cyan,
      ParallelPalette.pink,
      ParallelPalette.green,
      ParallelPalette.blue,
    ];
    return SizedBox(
      height: 56,
      child: Stack(
        children: [
          const Positioned(
            left: 0,
            top: 0,
            child: Icon(
              Icons.check_circle,
              size: 56,
              color: ParallelPalette.green,
            ),
          ),
          for (var i = 0; i < 12; i++)
            Positioned(
              left: 64 + (i * 23) % 220,
              top: (i * 17) % 44,
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: colors[i % colors.length],
                  borderRadius: BorderRadius.circular(
                    i.isEven ? 3.5 : 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
