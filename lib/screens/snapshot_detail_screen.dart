import 'package:material_ui/material_ui.dart';

import '../core/format.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../engine/models.dart';
import '../state/app_controller.dart';
import '../widgets/adaptive_shell.dart';
import '../widgets/frame_art.dart';
import 'screen_helpers.dart';

/// 08 — One snapshot: the message, the author, the time, and exactly what
/// changed.
class SnapshotDetailScreen extends StatelessWidget {
  /// Creates a [SnapshotDetailScreen].
  const SnapshotDetailScreen({
    required this.branchId,
    required this.snapshotId,
    super.key,
  });

  /// The branch id.
  final String branchId;
  /// The snapshot id.
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
        title: 'Snapshot',
        tab: 2,
        body: Center(child: Text('Snapshot not found.')),
      );
    }
    final snap = snapshot.first;
    final color = Color(branch.color);
    final frameKind = _frameKindFor(snap);

    return AdaptiveScaffold(
      title: 'Snapshot ${snap.id}',
      subtitle: 'on ${branch.name}',
      tab: 2,
      body: ScreenBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              snap.message,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${snap.id} · ${snap.author} · '
              '${formatRelative(snap.createdAt)} · on ${branch.name}',
              style: AppTheme.mono(
                size: 13,
                color: ParallelPalette.muted,
              ),
            ),
            if (snap.isMerge || snap.isRestore) ...[
              const SizedBox(height: 10),
              _TagRow(snap: snap, color: color),
            ],
            const SizedBox(height: 12),
            FrameArt(kind: frameKind, label: '${snap.id} · ${branch.name}'),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'What changed',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (snap.changes.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'No individual changes recorded for this snapshot.',
                          style: TextStyle(
                            fontSize: 14,
                            color: ParallelPalette.secondary,
                          ),
                        ),
                      )
                    else
                      for (var i = 0; i < snap.changes.length; i++) ...[
                        if (i > 0) const Divider(),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                _iconForKind(snap.changes[i].kind),
                                size: 18,
                                color: ParallelPalette.secondary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      snap.changes[i].detail,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      snap.changes[i].meta,
                                      style: AppTheme.mono(
                                        size: 12,
                                        color: ParallelPalette.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Card(
              color: ParallelPalette.paper2,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.history,
                      size: 18,
                      color: ParallelPalette.secondary,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Restoring adds a new snapshot',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'This snapshot stays exactly as it is. Nothing '
                            'is rewritten.',
                            style: TextStyle(
                              fontSize: 13,
                              color: ParallelPalette.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      if (!requireAccount(
                        context,
                        'branch from this snapshot',
                      )) {
                        return;
                      }
                      Navigator.pushNamed(
                        context,
                        Routes.newBranch,
                        arguments: NewBranchArgs(
                          forkFromSnapshotId: snap.id,
                        ),
                      );
                    },
                    child: const Text('Branch from here'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      if (!requireAccount(
                        context,
                        'restore a decision',
                      )) {
                        return;
                      }
                      Navigator.pushNamed(
                        context,
                        Routes.restore,
                        arguments: RestoreArgs(
                          branchId: branch.id,
                          snapshotId: snap.id,
                        ),
                      );
                    },
                    child: const Text('Restore'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Picks illustrative frame art from the snapshot's first change.
  String _frameKindFor(Snapshot snap) {
    if (snap.changes.isEmpty) return 'default';
    final scenes = snap.changes.first.scenes;
    if (scenes.contains(12)) return 'rooftop';
    if (scenes.contains(1)) return 'harbour';
    return 'default';
  }

  IconData _iconForKind(String kind) {
    switch (kind) {
      case 'shot':
        return Icons.movie;
      case 'order':
        return Icons.swap_horiz;
      case 'grade':
        return Icons.palette_outlined;
      case 'runtime':
        return Icons.schedule;
      case 'voiceover':
        return Icons.mic_none;
      case 'sound':
        return Icons.music_note;
      case 'credits':
        return Icons.theaters_outlined;
      case 'pacing':
        return Icons.speed;
      default:
        return Icons.edit_outlined;
    }
  }
}

class _TagRow extends StatelessWidget {
  const _TagRow({required this.snap, required this.color});

  final Snapshot snap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final label = snap.isMerge
        ? 'Merge of ${snap.mergeOf}'
        : 'Restores ${snap.restores}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
