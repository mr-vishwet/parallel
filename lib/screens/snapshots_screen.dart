import 'package:flutter/material.dart';

import '../core/routes.dart';
import '../core/theme.dart';
import '../state/app_controller.dart';
import '../widgets/adaptive_shell.dart';
import '../widgets/branch_chip.dart';
import '../widgets/snapshot_row.dart';

/// 07 — Snapshots on a branch, newest first. History only grows.
class SnapshotsScreen extends StatefulWidget {
  const SnapshotsScreen({this.branchId = 'main', super.key});

  final String branchId;

  @override
  State<SnapshotsScreen> createState() => _SnapshotsScreenState();
}

class _SnapshotsScreenState extends State<SnapshotsScreen> {
  late String _branchId;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _branchId = widget.branchId;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final project = controller.openProject;
    if (project == null) {
      return const AdaptiveScaffold(
        title: 'Snapshots',
        tab: 2,
        body: Center(child: Text('No project is open.')),
      );
    }
    final branch = project.branchById(_branchId) ?? project.mainBranch;
    final color = Color(branch.color);
    final needle = _query.trim().toLowerCase();
    final snapshots = needle.isEmpty
        ? branch.snapshots
        : branch.snapshots.where((s) {
            final haystack =
                '${s.message} ${s.author} ${s.id}'.toLowerCase();
            return haystack.contains(needle);
          }).toList();

    return AdaptiveScaffold(
      title: 'Snapshots',
      subtitle: '${branch.name} · ${branch.snapshotCount}',
      tab: 2,
      body: ScreenBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Kicker('History only grows'),
            const SizedBox(height: 6),
            Text(
              'Snapshots on ${branch.name}',
              style: const TextStyle(
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
                for (final b in project.branches)
                  BranchChip(
                    name: b.name,
                    color: Color(b.color),
                    selected: b.id == branch.id,
                    onTap: () => setState(() => _branchId = b.id),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search snapshots',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${branch.name} · ${branch.snapshotCount} snapshots',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      branch.latest == null
                          ? 'No snapshots yet'
                          : 'Newest first · ${branch.latest!.id} is the '
                              'latest cut',
                      style: const TextStyle(
                        fontSize: 12,
                        color: ParallelPalette.muted,
                      ),
                    ),
                    if (snapshots.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          needle.isEmpty
                              ? 'No snapshots on this branch yet.'
                              : 'Nothing matches “$_query” on ${branch.name}.',
                          style: const TextStyle(
                            fontSize: 14,
                            color: ParallelPalette.secondary,
                          ),
                        ),
                      )
                    else
                      for (var i = 0; i < snapshots.length; i++) ...[
                        if (i > 0) const Divider(),
                        SnapshotRow(
                          snapshot: snapshots[i],
                          color: color,
                          isLatest: i == 0 && needle.isEmpty,
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              Routes.snapshotDetail,
                              arguments: SnapshotArgs(
                                branchId: branch.id,
                                snapshotId: snapshots[i].id,
                              ),
                            );
                          },
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
