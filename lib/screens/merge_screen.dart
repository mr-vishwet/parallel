import 'package:flutter/material.dart';

import '../core/routes.dart';
import '../core/theme.dart';
import '../engine/branch_engine.dart';
import '../state/app_controller.dart';
import '../widgets/adaptive_shell.dart';
import '../widgets/change_row.dart';
import 'screen_helpers.dart';

/// 14 — Merge: the selected changes, the conflict flagged first. The
/// merge button waits behind the conflict — the app never merges past a
/// call the user has not made.
class MergeScreen extends StatefulWidget {
  const MergeScreen({required this.sourceId, required this.targetId, super.key});

  final String sourceId;
  final String targetId;

  @override
  State<MergeScreen> createState() => _MergeScreenState();
}

class _MergeScreenState extends State<MergeScreen> {
  bool _started = false;
  bool _merging = false;

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
        title: 'Merge',
        tab: 1,
        body: Center(child: Text('Branches not found.')),
      );
    }
    if (review == null ||
        review.sourceId != widget.sourceId ||
        review.targetId != widget.targetId) {
      return AdaptiveScaffold(
        title: 'Merge: ${source.name} → ${target.name}',
        tab: 1,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final plan = review.plan;
    final selectedChanges = review.diff.changes
        .where((c) => review.selectedIds.contains(c.id))
        .toList();
    final unresolved = review.diff.conflicts
        .where((c) => !review.resolutions.containsKey(c.id))
        .toList();
    final nextId = BranchEngine.nextSnapshotId(target);

    return AdaptiveScaffold(
      title: 'Merge: ${source.name} → ${target.name}',
      subtitle: '${selectedChanges.length} selected',
      tab: 1,
      body: ScreenBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Kicker('One branch joins another'),
            const SizedBox(height: 6),
            Text(
              '${source.name} into ${target.name}',
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              unresolved.isEmpty
                  ? '${selectedChanges.length} changes selected. '
                      'Ready to land.'
                  : '${selectedChanges.length} changes selected. '
                      '${unresolved.length} need${unresolved.length == 1 ? 's' : ''} '
                      'your call before the merge can land.',
              style: const TextStyle(
                fontSize: 15,
                color: ParallelPalette.secondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            if (selectedChanges.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No changes selected — go back to the diff and tick '
                    'what the merge should take.',
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
                      for (var i = 0; i < selectedChanges.length; i++) ...[
                        if (i > 0) const Divider(),
                        ChangeRow(
                          change: selectedChanges[i],
                          selectable: false,
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              Routes.changeDetail,
                              arguments: ChangeArgs(
                                changeId: selectedChanges[i].id,
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
            if (unresolved.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      Routes.conflict,
                      arguments: ChangeArgs(
                        changeId: unresolved.first.id,
                        sourceId: widget.sourceId,
                        targetId: widget.targetId,
                      ),
                    );
                  },
                  child: const Text('Resolve the conflict first'),
                ),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: !plan.canLand || _merging
                    ? null
                    : () async {
                        setState(() => _merging = true);
                        try {
                          final created =
                              await controller.executeMerge();
                          if (context.mounted) {
                            Navigator.pushReplacementNamed(
                              context,
                              Routes.merged,
                              arguments: MergedArgs(
                                branchId: target.id,
                                snapshotId: created.id,
                                sourceId: source.id,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) showError(context, e);
                          setState(() => _merging = false);
                        }
                      },
                child: Text(_merging ? 'Merging…' : 'Merge into ${target.name}'),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Merge creates $nextId · ${source.name} stays intact',
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
