import 'package:material_ui/material_ui.dart';

import '../core/routes.dart';
import '../core/theme.dart';
import '../engine/branch_engine.dart';
import '../engine/models.dart';
import '../state/app_controller.dart';
import '../widgets/adaptive_shell.dart';
import '../widgets/frame_art.dart';
import 'screen_helpers.dart';

/// 10 — One change up close: the two versions side by side, why it
/// matters, and the conflict flag when the change conflicts.
class ChangeDetailScreen extends StatelessWidget {
  /// Creates a [ChangeDetailScreen].
  const ChangeDetailScreen({
    required this.changeId,
    required this.sourceId,
    required this.targetId,
    super.key,
  });

  /// The change id.
  final String changeId;
  /// The source id.
  final String sourceId;
  /// The target id.
  final String targetId;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final project = controller.openProject;
    final source = project?.branchById(sourceId);
    final target = project?.branchById(targetId);
    if (project == null || source == null || target == null) {
      return const AdaptiveScaffold(
        title: 'Change',
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
    var index = 0;
    for (var i = 0; i < diff.changes.length; i++) {
      if (diff.changes[i].id == changeId) {
        change = diff.changes[i];
        index = i;
      }
    }
    if (change == null) {
      return const AdaptiveScaffold(
        title: 'Change',
        tab: 1,
        body: Center(child: Text('Change not found.')),
      );
    }
    final selected =
        review?.selectedIds.contains(change.id) ?? true;
    final sourceColor = Color(source.color);
    final targetColor = Color(target.color);

    return AdaptiveScaffold(
      title: 'Change ${index + 1} of ${diff.changes.length}',
      subtitle: '$sourceId vs $targetId',
      tab: 1,
      body: ScreenBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'The ${change.title.toLowerCase()} changed',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              change.detail,
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
                  child: _VersionPanel(
                    label: '${target.name} · now',
                    labelColor: ParallelPalette.muted,
                    title: _targetTitle(change, target),
                    meta: change.meta,
                    frameKind: _frameKind(change, isSource: false),
                    color: targetColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _VersionPanel(
                    label: source.name,
                    labelColor: sourceColor,
                    title: _sourceTitle(change, source),
                    meta: change.meta,
                    frameKind: _frameKind(change, isSource: true),
                    color: sourceColor,
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
                      'Why it matters',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _whyItMatters(change),
                      style: const TextStyle(
                        fontSize: 14,
                        color: ParallelPalette.secondary,
                        height: 1.55,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (change.conflict) ...[
              const SizedBox(height: 12),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: ParallelPalette.amber.withValues(alpha: 0.5),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        size: 18,
                        color: ParallelPalette.amberCta,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Conflict on this change',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              change.conflictNote ??
                                  'Both branches changed this after the fork.',
                              style: const TextStyle(
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
            ],
            const SizedBox(height: 12),
            if (change.conflict)
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      Routes.conflict,
                      arguments: ChangeArgs(
                        changeId: change!.id,
                        sourceId: sourceId,
                        targetId: targetId,
                      ),
                    );
                  },
                  child: const Text('Resolve this conflict'),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (!requireAccount(context, 'change the merge')) {
                      return;
                    }
                    // Ensure a live review exists (deep links arrive
                    // without one), then re-read the selection from it.
                    var current = controller.review;
                    if (current == null ||
                        current.sourceId != sourceId ||
                        current.targetId != targetId) {
                      controller.startReview(
                        sourceId: sourceId,
                        targetId: targetId,
                      );
                      current = controller.review;
                    }
                    final isSelected = current?.selectedIds
                            .contains(change!.id) ??
                        true;
                    controller.toggleChange(change!.id, !isSelected);
                    Navigator.pop(context);
                  },
                  child: Text(
                    selected
                        ? 'Leave this change behind'
                        : 'Include this change in the merge',
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
      return 'The boathouse';
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

  String _whyItMatters(Change change) {
    switch (change.kind) {
      case 'shot':
        return 'The first image sets the film. Change it and the next '
            'three scenes read differently either way.';
      case 'order':
        return 'Scene order is the argument of the film. What comes first '
            'frames everything after it.';
      case 'grade':
        return 'The grade is the film\'s temperature. Warmer shadows '
            'change how the night scenes feel, not what happens in them.';
      case 'runtime':
        return 'Runtime is attention. Longer holds ask the viewer to stay '
            'with a shot; shorter ones keep the film moving.';
      case 'voiceover':
        return 'The voiceover is the film\'s narrator. Keep it, trim it, '
            'or remove it — the scene plays differently each way.';
      default:
        return change.detail;
    }
  }
}

class _VersionPanel extends StatelessWidget {
  const _VersionPanel({
    required this.label,
    required this.labelColor,
    required this.title,
    required this.meta,
    required this.frameKind,
    required this.color,
  });

  final String label;
  final Color labelColor;
  final String title;
  final String meta;
  final String frameKind;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: labelColor),
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
          style: AppTheme.mono(size: 12, color: ParallelPalette.muted),
        ),
      ],
    );
  }
}
