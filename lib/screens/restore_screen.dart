import 'package:material_ui/material_ui.dart';

import '../core/format.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../engine/branch_engine.dart';
import '../state/app_controller.dart';
import '../widgets/adaptive_shell.dart';
import 'screen_helpers.dart';

/// 12 — Restore one decision: bring a snapshot back without touching
/// anything after it. The scope — what returns, what stays changed — is
/// the whole point.
class RestoreScreen extends StatefulWidget {
  /// Creates a [RestoreScreen].
  const RestoreScreen({
    required this.branchId,
    required this.snapshotId,
    super.key,
  });

  /// The branch id.
  final String branchId;
  /// The snapshot id.
  final String snapshotId;

  @override
  State<RestoreScreen> createState() => _RestoreScreenState();
}

class _RestoreScreenState extends State<RestoreScreen> {
  bool _restoring = false;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final project = controller.openProject;
    final branch = project?.branchById(widget.branchId);
    final snapshot = branch?.snapshots
        .where((s) => s.id == widget.snapshotId)
        .toList();
    if (project == null || branch == null || snapshot == null ||
        snapshot.isEmpty) {
      return const AdaptiveScaffold(
        title: 'Restore',
        tab: 2,
        body: Center(child: Text('Snapshot not found.')),
      );
    }
    final snap = snapshot.first;
    final scope = BranchEngine.restoreScope(branch: branch, snapshot: snap);
    final nextId = BranchEngine.nextSnapshotId(branch);

    return AdaptiveScaffold(
      title: 'Restore',
      subtitle: '${snap.id} · ${branch.name}',
      tab: 2,
      body: ScreenBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bring back\none decision',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Restore ${snap.id} without touching anything after it. '
              'The ${scope.staysChanged.length} snapshots since ${snap.id} '
              'stay exactly as they are.',
              style: const TextStyle(
                fontSize: 15,
                color: ParallelPalette.secondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${snap.id} · ${snap.author} · '
                      '${formatRelative(snap.createdAt)}',
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
                    if (snap.changes.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      for (final change in snap.changes)
                        Text(
                          '· ${change.detail}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: ParallelPalette.secondary,
                            height: 1.5,
                          ),
                        ),
                    ],
                    const Divider(height: 28),
                    _ScopeRow(
                      icon: Icons.undo,
                      iconColor: ParallelPalette.cutRed,
                      title: 'Returns',
                      sub: scope.returns.isEmpty
                          ? snap.restorePhrase
                          : scope.returns
                              .map((c) => c.title)
                              .join(' · '),
                    ),
                    const SizedBox(height: 10),
                    _ScopeRow(
                      icon: Icons.lock_outline,
                      iconColor: ParallelPalette.secondary,
                      title: 'Stays changed',
                      sub: scope.staysChanged.isEmpty
                          ? 'Nothing after ${snap.id} — it is the latest'
                          : scope.staysChanged
                              .map((s) => s.id)
                              .join(', '),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _restoring
                    ? null
                    : () async {
                        setState(() => _restoring = true);
                        try {
                          final created =
                              await controller.restoreSnapshot(
                            branchId: branch.id,
                            snapshotId: snap.id,
                          );
                          if (context.mounted) {
                            Navigator.pushReplacementNamed(
                              context,
                              Routes.restored,
                              arguments: RestoredArgs(
                                branchId: branch.id,
                                snapshotId: created.id,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) showError(context, e);
                          if (mounted) setState(() => _restoring = false);
                        }
                      },
                child: Text(
                  _restoring ? 'Restoring…' : 'Restore this decision',
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Restoring creates $nextId · history only grows',
                style: const TextStyle(
                  fontSize: 12,
                  color: ParallelPalette.muted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScopeRow extends StatelessWidget {
  const _ScopeRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.sub,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                sub,
                style: const TextStyle(
                  fontSize: 12,
                  color: ParallelPalette.muted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
