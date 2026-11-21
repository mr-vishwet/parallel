import 'package:material_ui/material_ui.dart';

import '../core/routes.dart';
import '../core/theme.dart';
import '../widgets/adaptive_shell.dart';

/// 26 — Upgrade prompt: branching needs an account. The demo stays open.
class UpgradeScreen extends StatelessWidget {
  /// Creates an [UpgradeScreen].
  const UpgradeScreen({required this.action, super.key});

  /// What the guest was trying to do, e.g. 'branch this project'.
  final String action;

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      title: 'Branching needs an account',
      subtitle: 'guest',
      showNav: false,
      body: ScreenBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Kicker('You are browsing the demo'),
            const SizedBox(height: 6),
            const Text(
              'Branching needs an account',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'You are looking at the demo as a guest. To $action — or '
              'start a project of your own — sign in or create an account.',
              style: const TextStyle(
                fontSize: 15,
                color: ParallelPalette.secondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            const Card(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What signing in adds',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    _WorksRow(
                      icon: Icons.account_tree_outlined,
                      title: 'Branch any project',
                      sub: 'Fork from any snapshot',
                    ),
                    Divider(),
                    _WorksRow(
                      icon: Icons.merge,
                      title: 'Merge and restore',
                      sub: 'Pick changes, resolve conflicts, bring back decisions',
                    ),
                    Divider(),
                    _WorksRow(
                      icon: Icons.sync,
                      title: 'Sync and share',
                      sub: 'Same branches on every device · invite Dev',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.pushNamed(context, Routes.createAccount);
                },
                child: const Text('Create an account'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Keep browsing the demo'),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, Routes.signIn);
                },
                child: const Text('Already have an account? Sign in'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorksRow extends StatelessWidget {
  const _WorksRow({
    required this.icon,
    required this.title,
    required this.sub,
  });

  final IconData icon;
  final String title;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
        ],
      ),
    );
  }
}
