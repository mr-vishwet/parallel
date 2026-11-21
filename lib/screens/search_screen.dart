import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../engine/branch_engine.dart';
import '../engine/models.dart';
import '../state/app_controller.dart';
import '../widgets/adaptive_shell.dart';

/// 18 — Search: snapshots across every branch, plus the related scene.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appController = AppScope.of(context);
    final project = appController.openProject;
    final hits = project == null
        ? <SnapshotHit>[]
        : BranchEngine.searchSnapshots(project, _query);
    final branchesHit = {for (final h in hits) h.branchId}.length;
    final relatedScene = _relatedScene(project, _query);

    return AdaptiveScaffold(
      title: 'Search',
      subtitle: _query.isEmpty ? null : '${hits.length} results',
      tab: 2,
      body: ScreenBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Search snapshots — try “voiceover”',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          setState(() => _query = '');
                        },
                      ),
              ),
              onChanged: (value) => setState(() => _query = value),
              textInputAction: TextInputAction.search,
            ),
            if (_query.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                '${hits.length} snapshot${hits.length == 1 ? '' : 's'}'
                '${branchesHit > 0 ? ' · across $branchesHit '
                    'branch${branchesHit == 1 ? '' : 'es'}' : ''}',
                style: const TextStyle(
                  fontSize: 12,
                  color: ParallelPalette.muted,
                ),
              ),
              const SizedBox(height: 12),
              if (hits.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No snapshot matches that. Search matches messages, '
                      'authors and snapshot ids.',
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
                        for (var i = 0; i < hits.length; i++) ...[
                          if (i > 0) const Divider(),
                          _HitRow(
                            hit: hits[i],
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                Routes.snapshotDetail,
                                arguments: SnapshotArgs(
                                  branchId: hits[i].branchId,
                                  snapshotId: hits[i].snapshot.id,
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              if (relatedScene != null) ...[
                const SizedBox(height: 12),
                Card(
                  color: ParallelPalette.paper2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Related',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Scene ${relatedScene.number}, '
                          '${relatedScene.title}: mentioned in '
                          '${hits.length} snapshot'
                          '${hits.length == 1 ? '' : 's'}. Compare it '
                          'across branches.',
                          style: const TextStyle(
                            fontSize: 14,
                            color: ParallelPalette.secondary,
                            height: 1.55,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              Routes.timeline,
                              arguments: TimelineArgs(
                                highlightScene: relatedScene.number,
                              ),
                            );
                          },
                          child: const Text('Open on the timeline'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ] else
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: Text(
                  'Search reads across branches — a word can live on main '
                  'and minimal at once.',
                  style: TextStyle(
                    fontSize: 14,
                    color: ParallelPalette.secondary,
                    height: 1.5,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Finds a scene whose title contains the query (for the Related card).
  Scene? _relatedScene(Project? project, String query) {
    if (project == null) return null;
    final needle = query.trim().toLowerCase();
    if (needle.length < 3) return null;
    for (final scene in project.scenes) {
      if (scene.title.toLowerCase().contains(needle)) return scene;
    }
    return null;
  }
}

class _HitRow extends StatelessWidget {
  const _HitRow({required this.hit, required this.onTap});

  final SnapshotHit hit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final snap = hit.snapshot;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              const Icon(
                Icons.commit,
                size: 18,
                color: ParallelPalette.secondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      snap.message,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${snap.id} · ${hit.branchId} · ${snap.author} · '
                      '${formatRelative(snap.createdAt)}',
                      style: AppTheme.mono(
                        size: 12,
                        color: ParallelPalette.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 16,
                color: ParallelPalette.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
