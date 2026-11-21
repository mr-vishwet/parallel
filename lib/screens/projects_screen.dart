import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../engine/models.dart';
import '../state/app_controller.dart';
import '../widgets/adaptive_shell.dart';
import '../widgets/branch_chip.dart';
import '../widgets/stat_card.dart';
import 'screen_helpers.dart';

/// 01 — Projects. The open project, the other projects, the merge in
/// review, and a way to start a new project.
class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final workspace = controller.workspace;
    final open = workspace.openProject;
    final mergesInReview = workspace.mergesInReview;

    return AdaptiveScaffold(
      title: 'Projects',
      subtitle: controller.signedIn
          ? '${controller.userName} · signed in'
          : 'Guest · view-only',
      tab: 0,
      body: ScreenBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${plural(workspace.projects.length, 'project')}, each with '
              'its own branches.',
              style: const TextStyle(
                fontSize: 15,
                color: ParallelPalette.secondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            StatRow(
              stats: [
                StatCard(
                  label: 'Branches',
                  figure: '${workspace.branchCount}',
                  sub:
                      '${open?.branches.length ?? 0} on ${open?.name ?? '—'}',
                ),
                StatCard(
                  label: 'Snapshots',
                  figure: '${workspace.snapshotCount}',
                  sub: '${open?.snapshotCount ?? 0} on ${open?.name ?? '—'}',
                ),
                StatCard(
                  label: 'Merges',
                  figure: '${workspace.mergeCount}',
                  sub: '$mergesInReview in review',
                ),
              ],
            ),
            const SizedBox(height: 16),
            for (final project in workspace.projects)
              _ProjectCard(
                project: project,
                isOpen: project.id == open?.id,
                onOpen: () async {
                  await controller.openProjectById(project.id);
                  if (context.mounted) {
                    Navigator.pushNamed(context, Routes.branchMap);
                  }
                },
              ),
            if (open?.mergeInReviewSource != null)
              _MergeInReviewCard(project: open!),
            const SizedBox(height: 8),
            _NewProjectCard(
              onTap: () {
                if (!requireAccount(context, 'start a project')) return;
                _showNewProjectDialog(context);
              },
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                '${workspace.projects.length} projects · '
                '${workspace.branchCount} branches · '
                '${workspace.snapshotCount} snapshots · all local-first',
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

  Future<void> _showNewProjectDialog(BuildContext context) async {
    final nameController = TextEditingController();
    var kind = 'Short film';
    const kinds = ['Short film', 'Brand film', 'Photo series', 'Design'];
    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('New project'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Project name',
                hintText: 'Harbour Light 2',
              ),
              textCapitalization: TextCapitalization.words,
              autofocus: true,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: kind,
              decoration: const InputDecoration(labelText: 'Kind'),
              items: kinds
                  .map((k) =>
                      DropdownMenuItem(value: k, child: Text(k)))
                  .toList(),
              onChanged: (value) {
                if (value != null) kind = value;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (created != true || !context.mounted) return;
    final controller = AppScope.of(context);
    try {
      await controller.createProject(name: nameController.text, kind: kind);
      if (context.mounted) {
        Navigator.pushNamed(context, Routes.branchMap);
      }
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.project,
    required this.isOpen,
    required this.onOpen,
  });

  final Project project;
  final bool isOpen;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final border = isOpen
        ? ParallelPalette.cutRed.withValues(alpha: 0.55)
        : ParallelPalette.hairline;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: border),
      ),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${project.kind} · ${project.subtitle}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: ParallelPalette.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isOpen)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: ParallelPalette.cutRed
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Open',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: ParallelPalette.cutRed,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${project.branches.length} branches · '
                '${project.snapshotCount} snapshots'
                '${project.archived ? ' · archived' : ''}',
                style: const TextStyle(
                  fontSize: 12,
                  color: ParallelPalette.muted,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final branch in project.branches)
                    BranchChip(
                      name: branch.name,
                      color: Color(branch.color),
                      onTap: () async {
                        await controller.openProjectById(project.id);
                        if (context.mounted) {
                          Navigator.pushNamed(
                            context,
                            Routes.branchDetail,
                            arguments: BranchArgs(branch.id),
                          );
                        }
                      },
                    ),
                ],
              ),
              if (project.isDemo && controller.signedIn) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      try {
                        await controller.forkProjectToAccount(project);
                        if (context.mounted) {
                          showMessage(
                            context,
                            '${project.name} forked into your account.',
                          );
                        }
                      } catch (e) {
                        if (context.mounted) showError(context, e);
                      }
                    },
                    icon: const Icon(Icons.copy_all_outlined, size: 16),
                    label: const Text('Fork into my account'),
                  ),
                ),
              ],
              if (project.isDemo)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Demo project — seeded content',
                    style: TextStyle(
                      fontSize: 11,
                      color: ParallelPalette.muted,
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

class _MergeInReviewCard extends StatelessWidget {
  const _MergeInReviewCard({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final source = project.branchById(project.mergeInReviewSource!);
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: ParallelPalette.amber.withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            Routes.diff,
            arguments: DiffArgs(
              sourceId: source?.id ?? '',
              targetId: 'main',
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Merge in review',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '1 conflict',
                    style: AppTheme.mono(
                      size: 12,
                      color: ParallelPalette.amberCta,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '${source?.name ?? ''} → main',
                style: const TextStyle(
                  fontSize: 13,
                  color: ParallelPalette.secondary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                '3 changes selected · resolve the opening first',
                style: TextStyle(
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

class _NewProjectCard extends StatelessWidget {
  const _NewProjectCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: ParallelPalette.paper2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.add, size: 18, color: ParallelPalette.secondary),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'New project',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Start from a cut, a script or an empty timeline',
                      style: TextStyle(
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
    );
  }
}
