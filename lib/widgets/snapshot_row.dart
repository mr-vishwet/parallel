import 'package:material_ui/material_ui.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../engine/models.dart';

/// One snapshot in a list: id dot, message, author · time, chevron.
/// The newest snapshot on a branch renders in the branch colour.
class SnapshotRow extends StatelessWidget {
  /// Creates a [SnapshotRow].
  const SnapshotRow({
    required this.snapshot,
    required this.color,
    this.isLatest = false,
    this.onTap,
    super.key,
  });

  /// The snapshot.
  final Snapshot snapshot;
  /// The color color.
  final Color color;
  /// Whether this is the latest snapshot.
  final bool isLatest;
  /// Called when tapped.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final dotColor =
        isLatest ? color : ParallelPalette.ink.withValues(alpha: 0.55);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                    boxShadow: isLatest
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.5),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      snapshot.message,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${snapshot.id} · ${snapshot.author} · '
                      '${formatRelative(snapshot.createdAt)}',
                      style: AppTheme.mono(
                        size: 12,
                        color: ParallelPalette.muted,
                      ),
                    ),
                    if (snapshot.isMerge || snapshot.isRestore) ...[
                      const SizedBox(height: 4),
                      _Tag(
                        label: snapshot.isMerge
                            ? 'Merge of ${snapshot.mergeOf}'
                            : 'Restores ${snapshot.restores}',
                        color: color,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: ParallelPalette.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
