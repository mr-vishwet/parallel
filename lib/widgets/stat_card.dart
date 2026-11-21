import 'package:flutter/material.dart';

import '../core/theme.dart';

/// A small stat: label above, big figure, sub-label below. Matches the V7
/// stat rows (Branches 7 · 4 on Harbour Light).
class StatCard extends StatelessWidget {
  const StatCard({
    required this.label,
    required this.figure,
    required this.sub,
    super.key,
  });

  final String label;
  final String figure;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: ParallelPalette.muted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            figure,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: ParallelPalette.ink,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: const TextStyle(
              fontSize: 12,
              color: ParallelPalette.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// A row of [StatCard]s with dividers, as on the projects and branch
/// screens.
class StatRow extends StatelessWidget {
  const StatRow({required this.stats, super.key});

  final List<StatCard> stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < stats.length; i++) ...[
          if (i > 0)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(
                height: 48,
                child: VerticalDivider(
                  color: ParallelPalette.hairline,
                  width: 1,
                ),
              ),
            ),
          stats[i],
        ],
      ],
    );
  }
}
