import 'package:material_ui/material_ui.dart';

import '../core/format.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../engine/models.dart';
import '../state/app_controller.dart';
import '../widgets/adaptive_shell.dart';
import '../widgets/branch_chip.dart';
import 'screen_helpers.dart';

/// 06 — New branch: name it, pick the snapshot to fork from.
class NewBranchScreen extends StatefulWidget {
  /// Creates a [NewBranchScreen].
  const NewBranchScreen({this.forkFromSnapshotId, super.key});

  /// The fork from snapshot id.
  final String? forkFromSnapshotId;

  @override
  State<NewBranchScreen> createState() => _NewBranchScreenState();
}

class _NewBranchScreenState extends State<NewBranchScreen> {
  final _nameController = TextEditingController(text: 'festival-cut');
  String _forkBranchId = 'main';
  String? _forkSnapshotId;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final project = controller.openProject;
    if (project == null) {
      return const AdaptiveScaffold(
        title: 'New branch',
        tab: 1,
        body: Center(child: Text('No project is open.')),
      );
    }
    final forkBranch =
        project.branchById(_forkBranchId) ?? project.mainBranch;
    final selectedId =
        _forkSnapshotId ?? widget.forkFromSnapshotId ?? forkBranch.latest?.id;
    Snapshot? selected;
    for (final s in forkBranch.snapshots) {
      if (s.id == selectedId) selected = s;
    }

    return AdaptiveScaffold(
      title: 'New branch',
      subtitle: project.name,
      tab: 1,
      body: ScreenBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Kicker('Fork the film'),
            const SizedBox(height: 6),
            const Text(
              'A branch starts\nfrom one snapshot',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Everything before it comes along; nothing after it does.',
              style: TextStyle(
                fontSize: 15,
                color: ParallelPalette.secondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'BRANCH NAME',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                color: ParallelPalette.muted,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: 'festival-cut',
              ),
              textCapitalization: TextCapitalization.none,
              autocorrect: false,
            ),
            const SizedBox(height: 16),
            const Text(
              'FORK FROM',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                color: ParallelPalette.muted,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final branch in project.branches)
                  BranchChip(
                    name: branch.name,
                    color: Color(branch.color),
                    selected: branch.id == forkBranch.id,
                    onTap: () {
                      setState(() {
                        _forkBranchId = branch.id;
                        _forkSnapshotId = branch.latest?.id;
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Fork from',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      selected == null
                          ? 'No snapshots on this branch yet'
                          : '${selected.id} selected · ${selected.message}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: ParallelPalette.muted,
                      ),
                    ),
                    for (var i = 0; i < forkBranch.snapshots.length; i++) ...[
                      if (i > 0) const Divider(),
                      _ForkOption(
                        snapshot: forkBranch.snapshots[i],
                        selected:
                            forkBranch.snapshots[i].id == selectedId,
                        onTap: () {
                          setState(() {
                            _forkSnapshotId = forkBranch.snapshots[i].id;
                          });
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving || selectedId == null
                    ? null
                    : () async {
                        setState(() => _saving = true);
                        try {
                          final branch =
                              await controller.createBranch(
                            name: _nameController.text,
                            forkFromId: selectedId,
                          );
                          if (context.mounted) {
                            Navigator.pushReplacementNamed(
                              context,
                              Routes.branchDetail,
                              arguments: BranchArgs(branch.id),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) showError(context, e);
                          if (mounted) setState(() => _saving = false);
                        }
                      },
                child: Text(
                  _saving ? 'Creating…' : 'Create branch',
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'Forking never changes main',
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
}

class _ForkOption extends StatelessWidget {
  const _ForkOption({
    required this.snapshot,
    required this.selected,
    required this.onTap,
  });

  final Snapshot snapshot;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: selected
                      ? ParallelPalette.cutRed
                      : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected
                        ? ParallelPalette.cutRed
                        : ParallelPalette.ink.withValues(alpha: 0.35),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      snapshot.message,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${snapshot.id} · ${snapshot.author} · '
                      '${formatRelative(snapshot.createdAt)}',
                      style: AppTheme.mono(
                        size: 12,
                        color: ParallelPalette.muted,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check,
                  size: 16,
                  color: ParallelPalette.cutRed,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
