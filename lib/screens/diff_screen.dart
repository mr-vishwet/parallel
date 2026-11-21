import 'package:material_ui/material_ui.dart';

import '../core/routes.dart';
import '../core/theme.dart';
import '../state/app_controller.dart';
import '../widgets/adaptive_shell.dart';
import '../widgets/change_row.dart';
import 'screen_helpers.dart';

/// 09 — The visual diff in human language: tick what the merge should
/// take. Starts the live merge review (or reuses the one already open
/// for this pair, so selections survive navigation).
class DiffScreen extends StatefulWidget {
  /// Creates a [DiffScreen].
  const DiffScreen({required this.sourceId, required this.targetId, super.key});

  /// The source id.
  final String sourceId;
  /// The target id.
  final String targetId;

  @override
  State<DiffScreen> createState() => _DiffScreenState();
}

class _DiffScreenState extends State<DiffScreen> {
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final controller = AppScope.of(context);
    final review = controller.review;
    if (review == null ||
        review.sourceId != widget.sourceId ||
        review.targetId != widget.targetId) {
      // Defer past the build so notifyListeners never fires mid-frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.startReview(
          sourceId: widget.sourceId,
          targetId: widget.targetId,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final project = controller.openProject;
    final source = project?.branchById(widget.sourceId);
    final target = project?.branchById(widget.targetId);
    final review = controller.review;
    if (project == null || source == null || target == null) {
      return const AdaptiveScaffold(
        title: 'Diff',
        tab: 1,
        body: Center(child: Text('Branches not found.')),
      );
    }
    if (review == null ||
        review.sourceId != widget.sourceId ||
        review.targetId != widget.targetId) {
      return AdaptiveScaffold(
        title: 'Diff: ${source.name} vs ${target.name}',
        tab: 1,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final changes = review.diff.changes;
    final selected = review.selectedCount;

    return AdaptiveScaffold(
      title: 'Diff: ${source.name} vs ${target.name}',
      subtitle: '${changes.length} changes',
      tab: 1,
      body: ScreenBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Kicker('In plain words'),
            const SizedBox(height: 6),
            Text(
              'What ${source.name}\nchanged',
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              changes.isEmpty
                  ? '${source.name} has no changes since it forked from '
                      '${target.name}.'
                  : 'Tick what the merge should take — $selected of '
                      '${changes.length} selected.',
              style: const TextStyle(
                fontSize: 15,
                color: ParallelPalette.secondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 12),
            if (changes.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Nothing to merge yet. Take a snapshot on the source '
                    'branch first.',
                    style: TextStyle(
                      fontSize: 14,
                      color: ParallelPalette.secondary,
                    ),
                  ),
                ),
              )
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                  child: Column(
                    children: [
                      for (var i = 0; i < changes.length; i++) ...[
                        if (i > 0) const Divider(),
                        ChangeRow(
                          change: changes[i],
                          selected: review.selectedIds
                              .contains(changes[i].id),
                          onToggle: (value) => controller.toggleChange(
                            changes[i].id,
                            value,
                          ),
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              Routes.changeDetail,
                              arguments: ChangeArgs(
                                changeId: changes[i].id,
                                sourceId: widget.sourceId,
                                targetId: widget.targetId,
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            if (changes.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: selected == 0
                      ? null
                      : () {
                          if (!requireAccount(
                            context,
                            'review this merge',
                          )) {
                            return;
                          }
                          Navigator.pushNamed(
                            context,
                            Routes.merge,
                            arguments: DiffArgs(
                              sourceId: widget.sourceId,
                              targetId: widget.targetId,
                            ),
                          );
                        },
                  child: Text('Review merge · $selected changes'),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Unticked changes stay on the source branch',
                  style: TextStyle(
                    fontSize: 12,
                    color: ParallelPalette.muted,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
