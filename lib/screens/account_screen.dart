import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../state/app_controller.dart';
import '../widgets/adaptive_shell.dart';

/// 28 — Account home: profile, projects, storage, collaborators.
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final workspace = controller.workspace;
    final name = controller.userName;
    final email = controller.userEmail;

    if (!controller.signedIn) {
      return AdaptiveScaffold(
        title: 'Account',
        tab: 3,
        body: ScreenBody(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'You are browsing as a guest.',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sign in to see your account — or create one to start '
                'branching your own work.',
                style: TextStyle(
                  fontSize: 15,
                  color: ParallelPalette.secondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pushNamed(context, Routes.signIn);
                  },
                  child: const Text('Sign in'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, Routes.createAccount);
                  },
                  child: const Text('Create an account'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final open = workspace.openProject;
    return AdaptiveScaffold(
      title: 'Account',
      tab: 3,
      body: ScreenBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: ParallelPalette.cutRed,
                  child: Text(
                    name.isEmpty ? '?' : name[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        email,
                        style: const TextStyle(
                          fontSize: 13,
                          color: ParallelPalette.secondary,
                        ),
                      ),
                      Text(
                        'Signed in · ${open?.name ?? 'no project'} open',
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
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  _Row(
                    icon: Icons.person_outline,
                    title: name,
                    sub: email,
                  ),
                  const Divider(),
                  _Row(
                    icon: Icons.folder_outlined,
                    title: 'Projects',
                    sub: '${workspace.projects.length} projects · '
                        '${workspace.branchCount} branches · '
                        '${workspace.snapshotCount} snapshots',
                    onTap: () => Navigator.pushNamed(
                      context,
                      Routes.projects,
                    ),
                  ),
                  const Divider(),
                  _Row(
                    icon: Icons.storage_outlined,
                    title: 'Storage',
                    sub: '${DemoFigures.storageOnDevice} on this device · '
                        'demo figure',
                  ),
                  const Divider(),
                  _Row(
                    icon: Icons.people_outline,
                    title: 'Collaborators',
                    sub: 'Dev · can branch and merge (demo)',
                  ),
                  const Divider(),
                  _Row(
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                    sub: 'Merges and mentions only',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Kicker('Your work — synced, counted'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _Stat(
                          value: '${workspace.projects.length}',
                          label: 'projects',
                        ),
                        _Stat(
                          value: '${workspace.branchCount}',
                          label: 'branches',
                        ),
                        _Stat(
                          value: '${workspace.snapshotCount}',
                          label: 'snapshots',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _Stat(
                          value: '${workspace.mergeCount}',
                          label: 'merges',
                        ),
                        _Stat(
                          value: '${workspace.mergesInReview}',
                          label: 'in review',
                        ),
                        _Stat(
                          value: DemoFigures.storageOnDevice,
                          label: 'on device',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pushNamed(context, Routes.connected);
                },
                child: const Text('Connected accounts'),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pushNamed(context, Routes.dataControls);
                },
                child: const Text('Data controls'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.title,
    required this.sub,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String sub;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 18, color: ParallelPalette.secondary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      sub,
                      style: const TextStyle(
                        fontSize: 13,
                        color: ParallelPalette.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
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

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: ParallelPalette.muted,
            ),
          ),
        ],
      ),
    );
  }
}
