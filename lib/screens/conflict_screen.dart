import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../engine/branch_engine.dart';
import '../engine/models.dart';
import '../state/app_controller.dart';
import '../widgets/adaptive_shell.dart';
import '../widgets/frame_art.dart';

/// 15 — The conflict: two openings, one film. You pick — PARALLEL never
/// guesses. The losing shot stays on its branch, exactly where it was.
class ConflictScreen extends StatelessWidget {
  const ConflictScreen({
    required this.changeId,
    required this.sourceId,
    required this.targetId,
    super.key,
  });

  final String changeId;
  final String sourceId;
  final String targetId;

  /// Records a resolution, ensuring a live review exists first (deep
  /// links arrive without one), then returns to the merge review.
  void _resolve(BuildContext context, String resolution) {
    final controller = AppScope.of(context);
    final current = controller.review;
    if (current == null ||
        current.sourceId != sourceId ||
        current.targetId != targetId) {
      controller.startReview(sourceId: sourceId, targetId: targetId);
    }
    controller.resolveConflict(changeId, resolution);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final project = controller.openProject;
    final source = project?.branchById(sourceId);
    final target = project?.branchById(targetId);
    if (project == null || source == null || target == null) {
      return const AdaptiveScaffold(
        title: 'Conflict',
        tab: 1,
        body: Center(child: Text('Branches not found.')),
      );
    }
    final review = controller.review;
    final diff = (review != null &&
            review.sourceId == sourceId &&
            review.targetId == targetId)
        ? review.diff
        : BranchEngine.diff(source: source, target: target);
    Change? change;
    var conflictIndex = 0;
    for (var i = 0; i < diff.conflicts.length; i++) {
      if (diff.conflicts[i].id == changeId) {
        change = diff.conflicts[i];
        conflictIndex = i;
      }
    }
    if (change == null) {
      return const AdaptiveScaffold(
        title: 'Conflict',
        tab: 1,
        body: Center(child: Text('Conflict not found.')),
      );
    }
    final resolved = review?.resolutions[change.id];
    final targetColor = Color(target.color);
    final sourceColor = Color(source.color);

    return AdaptiveScaffold(
      title: 'Conflict ${conflictIndex + 1} of ${diff.conflicts.length}',
      subtitle: change.title.toLowerCase(),
      tab: 1,
      body: ScreenBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Two openings, one film',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              change.conflictNote ??
                  'Both branches changed this after the fork. '
                      'PARALLEL does not guess — you pick.',
              style: const TextStyle(
                fontSize: 15,
                color: ParallelPalette.secondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _ChoicePanel(
                    label: '${target.name} · ${controller.userName}',
                    labelColor: ParallelPalette.muted,
                    title: _targetTitle(change, target),
                    meta: 'The version on ${target.name}',
                    frameKind: _frameKind(change, isSource: false),
                    color: targetColor,
                    chosen: resolved == 'target',
                    onTap: () => _resolve(context, 'target'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ChoicePanel(
                    label: '${source.name} · ${controller.userName}',
                    labelColor: sourceColor,
                    title: _sourceTitle(change, source),
                    meta: 'The version on ${source.name}',
                    frameKind: _frameKind(change, isSource: true),
                    color: sourceColor,
                    chosen: resolved == 'source',
                    onTap: () => _resolve(context, 'source'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'What happens to the other one',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'The losing shot stays on its branch, exactly where '
                      'it was. Nothing is deleted by a merge.',
                      style: TextStyle(
                        fontSize: 14,
                        color: ParallelPalette.secondary,
                        height: 1.55,
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
                  child: OutlinedButton(
                    onPressed: () => _resolve(context, 'target'),
                    child: Text('Keep ${target.name}'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _resolve(context, 'source'),
                    child: Text('Keep ${source.name}'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Center(
              child: Text(
                'Decided by you · recorded on the merge snapshot',
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

  String _targetTitle(Change change, Branch target) {
    if (change.kind == 'shot' && change.scenes.contains(1)) {
      return 'The boathouse, reframed';
    }
    return 'As ${target.name} has it';
  }

  String _sourceTitle(Change change, Branch source) {
    if (change.kind == 'shot' && change.scenes.contains(1)) {
      return 'Harbour dawn';
    }
    return 'As ${source.name} has it';
  }

  String _frameKind(Change change, {required bool isSource}) {
    if (change.kind == 'shot' && change.scenes.contains(1)) {
      return isSource ? 'harbour' : 'boathouse';
    }
    if (change.scenes.contains(12)) return 'rooftop';
    return 'default';
  }
}

class _ChoicePanel extends StatelessWidget {
  const _ChoicePanel({
    required this.label,
    required this.labelColor,
    required this.title,
    required this.meta,
    required this.frameKind,
    required this.color,
    required this.chosen,
    required this.onTap,
  });

  final String label;
  final Color labelColor;
  final String title;
  final String meta;
  final String frameKind;
  final Color color;
  final bool chosen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: chosen
                  ? color
                  : ParallelPalette.hairline,
              width: chosen ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(fontSize: 12, color: labelColor),
                    ),
                  ),
                  if (chosen)
                    Icon(Icons.check_circle, size: 16, color: color),
                ],
              ),
              const SizedBox(height: 6),
              FrameArt(kind: frameKind, height: 90, label: ''),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                meta,
                style: const TextStyle(
                  fontSize: 12,
                  color: ParallelPalette.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
