import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Decorative frame art for the diff and snapshot screens.
///
/// The V7 screens show film frames (boathouse, harbour dawn, rooftop).
/// v0.1 has no frame assets, so each frame is drawn in code: a gradient
/// sky, a horizon, and a label. It is illustrative UI art, not a still —
/// real frame thumbnails arrive with the media pipeline in phase 2.
class FrameArt extends StatelessWidget {
  const FrameArt({
    required this.kind,
    this.height = 140,
    this.label,
    super.key,
  });

  /// 'boathouse' | 'harbour' | 'rooftop' | anything else for a neutral frame.
  final String kind;
  final double height;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final (top, bottom, accent, icon, caption) = _palette();
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [top, bottom],
          ),
        ),
        child: Stack(
          children: [
            // Sun / moon.
            Positioned(
              right: 24,
              top: height * 0.18,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.5),
                      blurRadius: 18,
                      spreadRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
            // Horizon line.
            Positioned(
              left: 0,
              right: 0,
              top: height * 0.62,
              child: Container(
                height: 1.5,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
            // Foreground silhouette.
            Positioned(
              left: 18,
              bottom: 14,
              child: Icon(icon, size: 30, color: Colors.white70),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      label ?? caption,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black38,
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  (Color, Color, Color, IconData, String) _palette() {
    switch (kind) {
      case 'boathouse':
        return (
          const Color(0xFF5B4A3A),
          const Color(0xFF2A2118),
          const Color(0xFFFBBF24),
          Icons.cabin,
          'The boathouse · interior',
        );
      case 'harbour':
        return (
          const Color(0xFFF59E0B),
          const Color(0xFF7C3A0E),
          const Color(0xFFFFF7CC),
          Icons.sailing,
          'Harbour dawn · exterior',
        );
      case 'rooftop':
        return (
          const Color(0xFF4C1D95),
          const Color(0xFF1E1B4B),
          const Color(0xFFF472B6),
          Icons.apartment,
          'Rooftop take',
        );
      default:
        return (
          ParallelPalette.cutRed,
          const Color(0xFF431407),
          const Color(0xFFFBBF24),
          Icons.movie,
          'Frame',
        );
    }
  }
}
