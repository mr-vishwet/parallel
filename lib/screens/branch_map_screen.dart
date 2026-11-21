import 'package:material_ui/material_ui.dart';

import '../core/format.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../engine/models.dart';
import '../state/app_controller.dart';
import '../widgets/adaptive_shell.dart';
import '../widgets/branch_chip.dart';
import '../widgets/branch_map.dart';
import 'screen_helpers.dart';

/// 02 — The branch map: four glowing rails, the branch chips, and the
/// stepper to move between snapshots on the selected branch.
class BranchMapScreen extends StatefulWidget {
  /// Creates a [BranchMapScreen].
  const BranchMapScreen({super.key});

  @override
  State<BranchMapScreen> createState() => _BranchMapScreenState();
}

class _BranchMapScreenState extends State<BranchMapScreen> {
  String? _selectedBranchId;

  /// Stepper position within the selected branch (0 = newest).
  int _step = 0;

  void _selectBranch(String id) {
    setState(() {
      _selectedBranchId = id;
      _step = 0;
    });
  }

  void _stepBy(int delta, Branch branch) {
    final next = _step + delta;
    if (next < 0 || next >= branch.snapshots.length) return;
    setState(() => _step = next);
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final project = controller.openProject;
    if (project == null) {
      return const AdaptiveScaffold(
        title: 'Branch map',
        tab: 1,
        body: Center(child: Text('No project is open.')),
      );
    }
    final selected = project.branchById(
          _selectedBranchId ?? 'cinematic',
        ) ??
        project.mainBranch;
    final snapshots = selected.snapshots;
    // Clamped stepper index as an int (num.clamp returns num, which
    // cannot index a list).
    final stepIndex = snapshots.isEmpty
        ? 0
        : _step < 0
            ? 0
            : _step >= snapshots.length
                ? snapshots.length - 1
                : _step;
    final current = snapshots.isEmpty ? null : snapshots[stepIndex];
    final main = project.mainBranch;
    final delta = selected.runtimeSeconds - main.runtimeSeconds;

    return AdaptiveScaffold(
      title: 'Branch map',
      subtitle: project.name,
      tab: 1,
      body: ScreenBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Kicker('Step between timelines'),
            const SizedBox(height: 6),
            const Text(
              'Four timelines,\none film',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final branch in project.branches)
                  BranchChip(
                    name: branch.name,
                    color: Color(branch.color),
                    selected: branch.id == selected.id,
                    onTap: () => _selectBranch(branch.id),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            BranchMap(
              branches: project.branches,
              selectedId: selected.id,
              onSelect: _selectBranch,
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        BranchDot(
                          color: Color(selected.color),
                          size: 12,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selected.name,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                current == null
                                    ? 'No snapshots yet'
                                    : '${current.id} · ${current.message} · '
                                        '${current.author} · '
                                        '${formatRelative(current.createdAt)}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: ParallelPalette.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              formatDuration(selected.runtimeSeconds),
                              style: AppTheme.mono(
                                size: 15,
                                color: Color(selected.color),
                              ),
                            ),
                            Text(
                              selected.id == 'main'
                                  ? 'runtime'
                                  : formatRuntimeDelta(delta),
                              style: const TextStyle(
                                fontSize: 12,
                                color: ParallelPalette.muted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (snapshots.isNotEmpty) ...[
                      const Divider(height: 24),
                      Row(
                        children: [
                          _StepButton(
                            icon: Icons.chevron_left,
                            enabled: _step < snapshots.length - 1,
                            onTap: () => _stepBy(1, selected),
                          ),
                          Expanded(
                            child: Text(
                              '${snapshots.length - _step} of ${snapshots.length}',
                              textAlign: TextAlign.center,
                              style: AppTheme.mono(size: 13),
                            ),
                          ),
                          const Text(
                            'step through the branch',
                            style: TextStyle(
                              fontSize: 12,
                              color: ParallelPalette.muted,
                            ),
                          ),
                          const Spacer(),
                          _StepButton(
                            icon: Icons.chevron_right,
                            enabled: _step > 0,
                            onTap: () => _stepBy(-1, selected),
                          ),
                        ],
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
                    onPressed: () {
                      Navigator.pushNamed(context, Routes.compare);
                    },
                    child: const Text('Compare'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      if (!requireAccount(
                        context,
                        'create a branch',
                      )) {
                        return;
                      }
                      Navigator.pushNamed(context, Routes.newBranch);
                    },
                    child: const Text('New branch'),
                  ),
                ),
              ],
            ),
            if (current != null) ...[
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      Routes.snapshotDetail,
                      arguments: SnapshotArgs(
                        branchId: selected.id,
                        snapshotId: current.id,
                      ),
                    );
                  },
                  child: Text('Open snapshot ${current.id}'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled
          ? ParallelPalette.glassStrong
          : ParallelPalette.paper2,
      shape: const CircleBorder(
        side: BorderSide(color: ParallelPalette.hairline),
      ),
      child: InkWell(
        onTap: enabled ? onTap : null,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(
            icon,
            size: 18,
            color: enabled
                ? ParallelPalette.secondary
                : ParallelPalette.muted,
          ),
        ),
      ),
    );
  }
}
