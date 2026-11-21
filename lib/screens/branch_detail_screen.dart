import 'package:material_ui/material_ui.dart';

import '../core/format.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../engine/models.dart';
import '../state/app_controller.dart';
import '../widgets/adaptive_shell.dart';
import '../widgets/snapshot_row.dart';
import '../widgets/stat_card.dart';
import 'screen_helpers.dart';

/// 03 / 04 / 05 — One branch up close: runtime, snapshots, scenes
/// changed, and the way out to compare, merge, or take a snapshot.
/// Parameterized by branch id; the same screen serves cinematic, minimal,
/// experimental, main, and user-created branches.
class BranchDetailScreen extends StatelessWidget {
  /// Creates a [BranchDetailScreen].
  const BranchDetailScreen({required this.branchId, super.key});

  /// The branch id.
  final String branchId;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final project = controller.openProject;
    final branch = project?.branchById(branchId);
    if (project == null || branch == null) {
      return const AdaptiveScaffold(
        title: 'Branch',
        tab: 1,
        body: Center(child: Text('Branch not found.')),
      );
    }
    final color = Color(branch.color);
    final main = project.mainBranch;
    final delta = branch.runtimeSeconds - main.runtimeSeconds;
    final scenesChanged = {
      for (final snap in branch.snapshots)
        for (final change in snap.changes)
          ...change.scenes,
    }.length;
    final forkNote = branch.forkedFrom == null
        ? 'The first branch'
        : 'Forked from ${branch.forkedFrom}';

    return AdaptiveScaffold(
      title: 'Branch: ${branch.name}',
      subtitle: '${branch.name} · ${formatDuration(branch.runtimeSeconds)}',
      tab: 1,
      actions: [
        if (controller.canEdit)
          IconButton(
            icon: const Icon(Icons.add_a_photo_outlined),
            tooltip: 'Take snapshot',
            onPressed: () => _takeSnapshot(context, branch),
          ),
      ],
      body: ScreenBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Kicker('Branch · ${project.name}'),
            const SizedBox(height: 6),
            Text(
              branch.name,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              branch.tagline,
              style: const TextStyle(
                fontSize: 15,
                color: ParallelPalette.secondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 14),
            StatRow(
              stats: [
                StatCard(
                  label: 'Runtime',
                  figure: formatDuration(branch.runtimeSeconds),
                  sub: branch.id == 'main'
                      ? 'the locked cut'
                      : '${formatRuntimeDelta(delta)} vs main',
                ),
                StatCard(
                  label: 'Snapshots',
                  figure: '${branch.snapshotCount}',
                  sub: branch.latest == null
                      ? 'none yet'
                      : 'newest ${branch.latest!.id}',
                ),
                StatCard(
                  label: 'Scenes changed',
                  figure: '$scenesChanged',
                  sub: 'of ${project.scenes.length} scenes',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Snapshots',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '$forkNote · newest first',
                      style: const TextStyle(
                        fontSize: 12,
                        color: ParallelPalette.muted,
                      ),
                    ),
                    if (branch.snapshots.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'No snapshots yet — take the first one to start '
                          'this timeline.',
                          style: TextStyle(
                            fontSize: 14,
                            color: ParallelPalette.secondary,
                          ),
                        ),
                      )
                    else
                      for (var i = 0; i < branch.snapshots.length; i++) ...[
                        if (i > 0) const Divider(),
                        SnapshotRow(
                          snapshot: branch.snapshots[i],
                          color: color,
                          isLatest: i == 0,
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              Routes.snapshotDetail,
                              arguments: SnapshotArgs(
                                branchId: branch.id,
                                snapshotId: branch.snapshots[i].id,
                              ),
                            );
                          },
                        ),
                      ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: branch.id == 'main'
                        ? null
                        : () {
                            Navigator.pushNamed(
                              context,
                              Routes.diff,
                              arguments: DiffArgs(
                                sourceId: branch.id,
                                targetId: 'main',
                              ),
                            );
                          },
                    child: const Text('Compare with main'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: branch.id == 'main'
                        ? null
                        : () {
                            if (!requireAccount(
                              context,
                              'merge this branch',
                            )) {
                              return;
                            }
                            Navigator.pushNamed(
                              context,
                              Routes.merge,
                              arguments: DiffArgs(
                                sourceId: branch.id,
                                targetId: 'main',
                              ),
                            );
                          },
                    child: const Text('Merge'),
                  ),
                ),
              ],
            ),
            if (branch.id == 'main')
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  'main is the locked cut — other branches merge into it.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
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

  Future<void> _takeSnapshot(BuildContext context, Branch branch) async {
    if (!requireAccount(context, 'take a snapshot')) return;
    final messageController = TextEditingController();
    final detailController = TextEditingController();
    final controller = AppScope.of(context);
    final project = controller.openProject;
    var scene = project == null || project.scenes.isEmpty
        ? null
        : project.scenes.first.number;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text('Take a snapshot on ${branch.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: messageController,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  hintText: 'What did you decide?',
                ),
                textCapitalization: TextCapitalization.sentences,
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: detailController,
                decoration: const InputDecoration(
                  labelText: 'What changed (optional)',
                  hintText: 'In plain words',
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 12),
              if (project != null && project.scenes.isNotEmpty)
                DropdownButtonFormField<int>(
                  initialValue: scene,
                  decoration: const InputDecoration(labelText: 'Scene'),
                  items: project.scenes
                      .map((s) => DropdownMenuItem(
                            value: s.number,
                            child: Text('${s.number}. ${s.title}'),
                          ))
                      .toList(),
                  onChanged: (value) =>
                      setDialogState(() => scene = value),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Snapshot'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      final created = await controller.takeSnapshot(
        branchId: branch.id,
        message: messageController.text,
        changeDetail: detailController.text,
        scene: detailController.text.trim().isEmpty ? null : scene,
      );
      if (context.mounted) {
        showMessage(context, 'Snapshot ${created.id} added to ${branch.name}.');
      }
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }
}
