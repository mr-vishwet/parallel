import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../engine/models.dart';

/// One change in a diff list: checkbox, title, human-language detail,
/// meta line, and a conflict flag when present. Tapping the row opens the
/// change detail; tapping the checkbox toggles selection.
class ChangeRow extends StatelessWidget {
  const ChangeRow({
    required this.change,
    this.selected = false,
    this.selectable = true,
    this.onToggle,
    this.onTap,
    super.key,
  });

  final Change change;
  final bool selected;
  final bool selectable;
  final ValueChanged<bool>? onToggle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (selectable)
                Padding(
                  padding: const EdgeInsets.only(right: 12, top: 2),
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: Checkbox(
                      value: selected,
                      onChanged: (value) => onToggle?.call(value ?? false),
                      activeColor: ParallelPalette.cutRed,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            change.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (change.conflict)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: ParallelPalette.amber
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: ParallelPalette.amber,
                              ),
                            ),
                            child: const Text(
                              'Conflict',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: ParallelPalette.amberCta,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      change.detail,
                      style: const TextStyle(
                        fontSize: 13,
                        color: ParallelPalette.secondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      change.meta,
                      style: AppTheme.mono(
                        size: 12,
                        color: ParallelPalette.muted,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                const Padding(
                  padding: EdgeInsets.only(left: 8, top: 2),
                  child: Icon(
                    Icons.chevron_right,
                    size: 18,
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
