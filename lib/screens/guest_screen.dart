import 'package:material_ui/material_ui.dart';

import '../core/routes.dart';
import '../core/theme.dart';
import '../state/app_controller.dart';
import '../widgets/adaptive_shell.dart';

/// 22 — Guest mode is a viewing room: look at everything, change nothing.
class GuestScreen extends StatelessWidget {
  /// Creates a [GuestScreen].
  const GuestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);

    return AdaptiveScaffold(
      title: 'Guest mode',
      subtitle: 'view-only',
      tab: 3,
      body: ScreenBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Kicker('A viewing room'),
            const SizedBox(height: 6),
            const Text(
              'Guest mode is\na viewing room',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'You can open every branch and read every snapshot of the '
              'demo. You cannot change anything until you sign in.',
              style: TextStyle(
                fontSize: 15,
                color: ParallelPalette.secondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            const Card(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 6, 16, 6),
                child: Column(
                  children: [
                    _CapabilityRow(
                      icon: Icons.visibility_outlined,
                      title: 'Look around the demo',
                      sub: 'Branch map, diffs, snapshots — all readable',
                      allowed: true,
                    ),
                    Divider(),
                    _CapabilityRow(
                      icon: Icons.account_tree_outlined,
                      title: 'Branch your own project',
                      sub: 'Needs an account',
                      allowed: false,
                    ),
                    Divider(),
                    _CapabilityRow(
                      icon: Icons.merge,
                      title: 'Merge changes',
                      sub: 'Needs an account',
                      allowed: false,
                    ),
                    Divider(),
                    _CapabilityRow(
                      icon: Icons.undo,
                      title: 'Restore a decision',
                      sub: 'Needs an account',
                      allowed: false,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Card(
              color: ParallelPalette.paper2,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your work so far',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '0 projects · 0 branches · 0 snapshots — guests '
                      'create nothing, so there is nothing to lose',
                      style: TextStyle(
                        fontSize: 13,
                        color: ParallelPalette.secondary,
                      ),
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
                  Navigator.pushReplacementNamed(
                    context,
                    Routes.projects,
                  );
                },
                child: const Text('Open the demo'),
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
            if (controller.isGuest) ...[
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
          ],
        ),
      ),
    );
  }
}

class _CapabilityRow extends StatelessWidget {
  const _CapabilityRow({
    required this.icon,
    required this.title,
    required this.sub,
    required this.allowed,
  });

  final IconData icon;
  final String title;
  final String sub;
  final bool allowed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
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
          Icon(
            allowed ? Icons.check : Icons.lock_outline,
            size: 18,
            color: allowed
                ? ParallelPalette.green
                : ParallelPalette.muted,
          ),
        ],
      ),
    );
  }
}
