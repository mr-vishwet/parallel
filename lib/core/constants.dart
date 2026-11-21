/// Canonical constants for PARALLEL: storage keys, branch palette, demo
/// figures and app metadata.
///
/// The demo figures here are SEEDED DEMO CONTENT from the V7 design
/// (Harbour Light, 3:48, 14 scenes, 4 branches, 21 snapshots). They are
/// labelled as demo wherever they show in the UI; nothing here is a
/// measured claim about a real project.
library;

/// App identity.
class AppInfo {
  static const String name = 'PARALLEL';
  static const String tagline = 'Git for creative work';
  static const String version = '0.1.0';
  static const String buildLabel = 'v0.1 build — Build Specification';
}

/// SharedPreferences keys. One key per document; the workspace is a single
/// JSON document (local-first, no backend in v0.1).
class StoreKeys {
  static const String workspace = 'parallel.workspace.v1';
  static const String settings = 'parallel.settings.v1';
  static const String auth = 'parallel.auth.v1';
}

/// Branch glow colours from the V7 design: main cut-red, cinematic amber,
/// minimal cyan, experimental pink. New user branches cycle through
/// [newBranchColors] in order.
class BranchPalette {
  /// ARGB colour for a branch id. Unknown ids fall back to cut-red.
  static const Map<String, int> byBranchId = {
    'main': 0xFFB03220,
    'cinematic': 0xFFFBBF24,
    'minimal': 0xFF67E8F9,
    'experimental': 0xFFF472B6,
  };

  /// Colours for user-created branches, in cycle order.
  static const List<int> newBranchColors = [
    0xFF60A5FA, // blue
    0xFF34D399, // green
    0xFFA78BFA, // violet
    0xFFFBBF24, // amber
    0xFFF472B6, // pink
    0xFF67E8F9, // cyan
  ];

  static const int fallback = 0xFFB03220;
}

/// Demo figures shown in the UI. These describe the SEEDED demo workspace
/// (Harbour Light et al.) and are labelled as demo content in the UI.
class DemoFigures {
  /// Storage shown for the demo workspace. A demo figure, not a measurement.
  static const String storageOnDevice = '2.1 GB';

  /// Demo authors.
  static const String authorMara = 'Mara';
  static const String authorDev = 'Dev';
}

/// Breakpoint between the phone layout and the desktop shell.
const double kDesktopBreakpoint = 720.0;

/// Maximum content width in the desktop shell.
const double kDesktopMaxWidth = 1080.0;
