import 'package:material_ui/material_ui.dart';

import '../core/theme.dart';

/// A glowing dot in a branch's colour.
class BranchDot extends StatelessWidget {
  /// Creates a [BranchDot].
  const BranchDot({required this.color, this.size = 10, super.key});

  /// The color color.
  final Color color;
  /// The size.
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.55),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}

/// A pill chip for a branch name, glowing in the branch colour when
/// selected. Used on the branch map and the compare picker.
class BranchChip extends StatelessWidget {
  /// Creates a [BranchChip].
  const BranchChip({
    required this.name,
    required this.color,
    this.selected = false,
    this.badge,
    this.onTap,
    super.key,
  });

  /// The name.
  final String name;
  /// The color color.
  final Color color;
  /// Whether the chip is selected.
  final bool selected;

  /// Optional letter badge ('A' / 'B' on the compare screen).
  final String? badge;
  /// Called when tapped.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final badge = this.badge;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.16)
                : ParallelPalette.glassStrong,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? color
                  : ParallelPalette.hairline,
              width: 1.5,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.35),
                      blurRadius: 12,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (badge != null) ...[
                Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              BranchDot(color: color, size: 9),
              const SizedBox(width: 8),
              Text(
                name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w600,
                  color: ParallelPalette.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
