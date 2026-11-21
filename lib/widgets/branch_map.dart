import 'package:material_ui/material_ui.dart';

import '../core/theme.dart';
import '../engine/models.dart';

/// The branch map: one glowing rail per branch, a dot per snapshot, the
/// selected rail lit and the others quiet. Tapping a rail selects it.
class BranchMap extends StatelessWidget {
  /// Creates a [BranchMap].
  const BranchMap({
    required this.branches,
    required this.selectedId,
    required this.onSelect,
    super.key,
  });

  /// The branches.
  final List<Branch> branches;
  /// The selected id.
  final String selectedId;
  /// Called when selected.
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          children: [
            for (final branch in branches)
              _Rail(
                branch: branch,
                selected: branch.id == selectedId,
                onTap: () => onSelect(branch.id),
              ),
          ],
        ),
      ),
    );
  }
}

class _Rail extends StatelessWidget {
  const _Rail({
    required this.branch,
    required this.selected,
    required this.onTap,
  });

  final Branch branch;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Color(branch.color);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              SizedBox(
                width: 104,
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.6),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        branch.name,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: selected
                              ? ParallelPalette.ink
                              : ParallelPalette.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CustomPaint(
                  size: const Size(double.infinity, 20),
                  painter: _RailPainter(
                    color: color,
                    dots: branch.snapshotCount,
                    lit: selected,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                branch.latest?.id ?? '—',
                style: AppTheme.mono(size: 12, color: ParallelPalette.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RailPainter extends CustomPainter {
  const _RailPainter({
    required this.color,
    required this.dots,
    required this.lit,
  });

  final Color color;
  final int dots;
  final bool lit;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    final linePaint = Paint()
      ..color = lit
          ? color.withValues(alpha: 0.85)
          : color.withValues(alpha: 0.35)
      ..strokeWidth = lit ? 3 : 2
      ..strokeCap = StrokeCap.round;
    if (lit) {
      linePaint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    }
    canvas.drawLine(Offset(4, y), Offset(size.width - 4, y), linePaint);
    if (dots == 0) return;
    final dotPaint = Paint()..color = lit ? color : Colors.white;
    final ringPaint = Paint()
      ..color = color.withValues(alpha: lit ? 0.9 : 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (var i = 0; i < dots; i++) {
      final t = dots == 1 ? 1.0 : i / (dots - 1);
      final x = 4 + t * (size.width - 8);
      final isLast = i == dots - 1;
      canvas.drawCircle(Offset(x, y), isLast ? 6 : 4.5, dotPaint);
      canvas.drawCircle(Offset(x, y), isLast ? 6 : 4.5, ringPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RailPainter oldDelegate) =>
      color != oldDelegate.color ||
      dots != oldDelegate.dots ||
      lit != oldDelegate.lit;
}
