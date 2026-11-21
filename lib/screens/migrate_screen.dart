import 'package:flutter/material.dart';

import '../core/routes.dart';
import '../core/theme.dart';
import '../widgets/adaptive_shell.dart';

/// 27 — Moving your data: nothing lost. Guests create nothing, so 0
/// projects, 0 branches, 0 snapshots move.
class MigrateScreen extends StatelessWidget {
  const MigrateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      title: 'Moving your data',
      showNav: false,
      body: ScreenBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.check_circle,
                  size: 18,
                  color: ParallelPalette.green,
                ),
                SizedBox(width: 12),
                Text(
                  'Nothing lost',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Guest mode never created anything, so there is nothing to move',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Your account starts empty, and the demo stays where it was.',
              style: TextStyle(
                fontSize: 15,
                color: ParallelPalette.secondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                child: Column(
                  children: const [
                    _MoveRow(label: 'Projects'),
                    Divider(),
                    _MoveRow(label: 'Branches'),
                    Divider(),
                    _MoveRow(label: 'Snapshots'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              color: ParallelPalette.paper2,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'The demo is not yours',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Harbour Light belongs to the demo. Fork it into '
                      'your account if you want your own copy.',
                      style: TextStyle(
                        fontSize: 14,
                        color: ParallelPalette.secondary,
                        height: 1.55,
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
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    Routes.projects,
                    (route) => false,
                  );
                },
                child: const Text('Continue to your projects'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoveRow extends StatelessWidget {
  const _MoveRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            '0 to move',
            style: AppTheme.mono(
              size: 13,
              color: ParallelPalette.secondary,
            ),
          ),
        ],
      ),
    );
  }
}
