import 'package:material_ui/material_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme.dart';

/// The PARALLEL logo, composed in Flutter.
///
/// The SVG icon renders via flutter_svg. The horizontal and stacked
/// lockups carry `<text>` elements that flutter_svg cannot render, so the
/// wordmark is a Flutter [Text] widget set in Space Grotesk next to the
/// icon — the same lockup, composed natively.
class AppLogo {
  AppLogo._();

  /// Icon only (the two timelines meeting over the frame).
  static Widget icon({double size = 40}) => SvgPicture.asset(
        'assets/logos/icon.svg',
        width: size,
        height: size,
        semanticsLabel: 'PARALLEL logo',
      );

  /// App-icon tile (dark rounded square).
  static Widget appIcon({double size = 56}) => ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.22),
        child: SvgPicture.asset(
          'assets/logos/app-icon.svg',
          width: size,
          height: size,
          semanticsLabel: 'PARALLEL app icon',
        ),
      );

  /// Horizontal lockup: icon + PARALLEL wordmark.
  static Widget horizontal({double iconSize = 32}) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon(size: iconSize),
          const SizedBox(width: 10),
          Text(
            'PARALLEL',
            style: GoogleFonts.spaceGrotesk(
              fontSize: iconSize * 0.62,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              color: ParallelPalette.ink,
            ),
          ),
        ],
      );

  /// Stacked lockup: icon above the wordmark.
  static Widget stacked({double iconSize = 72}) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon(size: iconSize),
          const SizedBox(height: 12),
          Text(
            'PARALLEL',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: 4,
              color: ParallelPalette.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Git for creative work',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              color: ParallelPalette.secondary,
            ),
          ),
        ],
      );
}
