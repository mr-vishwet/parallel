import 'package:flutter/material.dart';

import '../core/routes.dart';
import '../core/theme.dart';
import '../state/app_controller.dart';
import '../widgets/adaptive_shell.dart';
import '../widgets/app_logo.dart';
import '../widgets/branch_chip.dart';

/// 21 — Welcome: browse the demo as a guest, or sign in to branch your
/// own work.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final project = controller.openProject;

    return AdaptiveScaffold(
      title: 'Welcome',
      showNav: false,
      body: ScreenBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppLogo.horizontal(iconSize: 30),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: ParallelPalette.cutRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Guest-first',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: ParallelPalette.cutRed,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Branch your own work,\nor browse the demo',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'The demo project, Harbour Light, is open to everyone to '
              'look around. Branching, merging and restoring need an account.',
              style: TextStyle(
                fontSize: 15,
                color: ParallelPalette.secondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            if (project != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Kicker('In the demo'),
                      const SizedBox(height: 6),
                      Text(
                        '${project.name} · ${project.branches.length} '
                        'branches · ${project.snapshotCount} snapshots · '
                        '2 merges on record',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
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
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  await controller.continueAsGuest();
                  if (context.mounted) {
                    Navigator.pushReplacementNamed(
                      context,
                      Routes.projects,
                    );
                  }
                },
                child: const Text('Continue as guest'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pushNamed(context, Routes.signIn);
                },
                child: const Text('Sign in'),
              ),
            ),
            const SizedBox(height: 12),
            const Center(
              child: Text(
                'Guest is view-only · no email needed',
                style: TextStyle(
                  fontSize: 13,
                  color: ParallelPalette.secondary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, Routes.createAccount);
                },
                child: const Text('No account yet? Create one'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
