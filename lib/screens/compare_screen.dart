import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../engine/branch_engine.dart';
import '../state/app_controller.dart';
import '../widgets/adaptive_shell.dart';
import '../widgets/branch_chip.dart';

/// 11 — Compare: pick any two branches and read the difference between
/// them. A is the base, B is the branch whose changes are read.
class CompareScreen extends StatefulWidget {
  const CompareScreen({super.key});

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  String _aId = 'cinematic';
  String _bId = 'minimal';

  void _pick(String branchId) {
    setState(() {
      if (branchId == _aId) {
        // Tapping A again clears it; B becomes A.
        _aId = _bId;
        _bId = '';
      } else if (branchId == _bId) {
        _bId = '';
      } else if (_bId.isEmpty) {
        _bId = branchId;
      } else {
        // Both filled: the tap replaces B.
        _bId = branchId;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final project = controller.openProject;
    if (project == null) {
      return const AdaptiveScaffold(
        title: 'Compare',
        tab: 1,
        body: Center(child: Text('No project is open.')),
      );
    }
    final a = project.branchById(_aId);
    final b = _bId.isEmpty ? null : project.branchById(_bId);
    final diff = (a != null && b != null)
        ? BranchEngine.diff(source: b, target: a)
        : null;
    final scenesDiffer = diff == null
        ? 0
        : {
            for (final c in diff.changes) ...c.scenes,
          }.length;

    return AdaptiveScaffold(
      title: 'Compare',
      subtitle: 'pick two',
      tab: 1,
      body: ScreenBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Kicker('Two timelines, side by side'),
            const SizedBox(height: 6),
            const Text(
              'Pick two branches',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'The diff reads the difference between them, not between files.',
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
                    for (var i = 0; i < project.branches.length; i++) ...[
                      if (i > 0) const Divider(),
                      _BranchPickRow(
                        name: project.branches[i].name,
                        tagline: project.branches[i].tagline,
                        runtime: formatDuration(
                          project.branches[i].runtimeSeconds,
                        ),
                        delta: project.branches[i].id == 'main'
                            ? '±0s vs main'
                            : '${formatRuntimeDelta(project.branches[i].runtimeSeconds - project.mainBranch.runtimeSeconds)} vs main',
                        color: Color(project.branches[i].color),
                        badge: project.branches[i].id == _aId
                            ? 'A'
                            : project.branches[i].id == _bId
                                ? 'B'
                                : null,
                        onTap: () => _pick(project.branches[i].id),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (a != null && b != null && diff != null) ...[
              const SizedBox(height: 12),
              Card(
                color: ParallelPalette.paper2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${a.name} vs ${b.name}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${a.tagline} ${b.tagline}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: ParallelPalette.secondary,
                          height: 1.55,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${diff.changes.length} changes · '
                        '${(b.runtimeSeconds - a.runtimeSeconds).abs()} '
                        'seconds apart · $scenesDiffer scenes differ',
                        style: AppTheme.mono(
                          size: 12,
                          color: ParallelPalette.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: (a == null || b == null || a.id == b.id)
                    ? null
                    : () {
                        Navigator.pushNamed(
                          context,
                          Routes.diff,
                          arguments: DiffArgs(
                            sourceId: b.id,
                            targetId: a.id,
                          ),
                        );
                      },
                child: const Text('Show the diff'),
              ),
            ),
            if (a == null || b == null)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Center(
                  child: Text(
                    'Pick two branches to compare them.',
                    style: TextStyle(
                      fontSize: 12,
                      color: ParallelPalette.muted,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BranchPickRow extends StatelessWidget {
  const _BranchPickRow({
    required this.name,
    required this.tagline,
    required this.runtime,
    required this.delta,
    required this.color,
    required this.badge,
    required this.onTap,
  });

  final String name;
  final String tagline;
  final String runtime;
  final String delta;
  final Color color;
  final String? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              BranchDot(color: color, size: 10),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      tagline,
                      style: const TextStyle(
                        fontSize: 12,
                        color: ParallelPalette.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    runtime,
                    style: AppTheme.mono(size: 13),
                  ),
                  Text(
                    delta,
                    style: const TextStyle(
                      fontSize: 12,
                      color: ParallelPalette.muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              if (badge != null)
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                )
              else
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: ParallelPalette.ink.withValues(alpha: 0.25),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
