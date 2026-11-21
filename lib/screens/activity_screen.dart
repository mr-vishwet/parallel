import 'package:material_ui/material_ui.dart';

import '../core/theme.dart';
import '../engine/models.dart';
import '../state/app_controller.dart';
import '../widgets/adaptive_shell.dart';

/// 19 — Activity: every branch, merge and restore, with the person
/// attached. Nothing here is automatic.
class ActivityScreen extends StatelessWidget {
  /// Creates an [ActivityScreen].
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final activity = controller.workspace.activity;

    return AdaptiveScaffold(
      title: 'Activity',
      subtitle: controller.openProject?.name,
      tab: 2,
      body: ScreenBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Kicker('Nothing here is automatic'),
            const SizedBox(height: 6),
            const Text(
              'Every branch,\nmerge and restore',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'With the person attached.',
              style: TextStyle(
                fontSize: 15,
                color: ParallelPalette.secondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                child: Column(
                  children: [
                    if (activity.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'Nothing yet — branch, merge or restore and it '
                          'shows up here.',
                          style: TextStyle(
                            fontSize: 14,
                            color: ParallelPalette.secondary,
                          ),
                        ),
                      )
                    else
                      for (var i = 0; i < activity.length; i++) ...[
                        if (i > 0) const Divider(),
                        _EventRow(event: activity[i]),
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

class _EventRow extends StatelessWidget {
  const _EventRow({required this.event});

  final ActivityEvent event;

  @override
  Widget build(BuildContext context) {
    final isMerge = event.kind == 'merge';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _iconFor(event.kind),
            size: 18,
            color: isMerge
                ? ParallelPalette.cutRed
                : ParallelPalette.secondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.text,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  event.ref,
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
    );
  }

  IconData _iconFor(String kind) {
    switch (kind) {
      case 'merge':
        return Icons.merge;
      case 'restore':
        return Icons.undo;
      case 'branch':
        return Icons.account_tree_outlined;
      case 'project':
        return Icons.folder_outlined;
      default:
        return Icons.commit;
    }
  }
}
