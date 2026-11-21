import 'package:flutter/material.dart';

import '../core/routes.dart';
import '../core/theme.dart';
import '../engine/branch_engine.dart';
import '../engine/models.dart';
import '../state/app_controller.dart';
import '../widgets/adaptive_shell.dart';

/// 17 — Timeline: one row per scene; the mark shows which branch last
/// changed it (computed from real snapshot history).
class TimelineScreen extends StatelessWidget {
  const TimelineScreen({this.highlightScene, super.key});

  final int? highlightScene;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final project = controller.openProject;
    if (project == null) {
      return const AdaptiveScaffold(
        title: 'Timeline',
        tab: 1,
        body: Center(child: Text('No project is open.')),
      );
    }
    final lastChanged = BranchEngine.sceneLastChanged(project);

    return AdaptiveScaffold(
      title: 'Timeline',
      subtitle: '${project.scenes.length} scenes',
      tab: 1,
      body: ScreenBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Kicker('One row per scene'),
            const SizedBox(height: 6),
            const Text(
              'Every scene,\nevery branch',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'The mark shows which branch last changed the scene.',
              style: TextStyle(
                fontSize: 15,
                color: ParallelPalette.secondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                child: Column(
                  children: [
                    for (var i = 0; i < project.scenes.length; i++) ...[
                      if (i > 0) const Divider(),
                      _SceneRow(
                        scene: project.scenes[i],
                        lastChangedBy: lastChanged[project.scenes[i].number],
                        project: project,
                        highlighted:
                            project.scenes[i].number == highlightScene,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SceneRow extends StatelessWidget {
  const _SceneRow({
    required this.scene,
    required this.lastChangedBy,
    required this.project,
    required this.highlighted,
  });

  final Scene scene;
  final String? lastChangedBy;
  final Project project;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final branch =
        lastChangedBy == null ? null : project.branchById(lastChangedBy!);
    final color =
        branch == null ? ParallelPalette.muted : Color(branch.color);
    return Material(
      color: highlighted
          ? ParallelPalette.cutRed.withValues(alpha: 0.06)
          : Colors.transparent,
      child: InkWell(
        onTap: () => _showSceneDetail(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              SizedBox(
                width: 26,
                child: Text(
                  scene.number.toString().padLeft(2, '0'),
                  style: AppTheme.mono(
                    size: 12,
                    color: ParallelPalette.muted,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  scene.title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                branch == null
                    ? 'Same on every branch'
                    : 'Changed on ${branch.name}',
                style: AppTheme.mono(size: 11, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSceneDetail(BuildContext context) {
    final sceneNumber = scene.number;
    final sceneTitle = scene.title;
    final touches = <(String, String, String)>[];
    for (final branch in project.branches) {
      for (final snap in branch.snapshots) {
        for (final change in snap.changes) {
          if (change.scenes.contains(sceneNumber)) {
            touches.add((branch.name, snap.id, change.detail));
          }
        }
      }
    }
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Scene $sceneNumber · $sceneTitle'),
        content: touches.isEmpty
            ? const Text(
                'No snapshot has changed this scene yet — it is the same '
                'on every branch.',
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final (branchName, snapId, detail) in touches)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$snapId · $branchName',
                            style: AppTheme.mono(
                              size: 12,
                              color: ParallelPalette.muted,
                            ),
                          ),
                          Text(
                            detail,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (touches.isNotEmpty)
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, Routes.compare);
              },
              child: const Text('Compare branches'),
            ),
        ],
      ),
    );
  }
}
