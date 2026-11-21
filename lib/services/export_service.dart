import 'dart:convert';

import 'package:flutter/services.dart';

import '../engine/models.dart';
import 'export_io.dart' if (dart.library.js_interop) 'export_stub.dart'
    as platform_export;

/// Export: the whole workspace as one JSON document.
///
/// Two ways out: copy to the clipboard (every platform) or save a file
/// (native platforms write to the app documents directory; web has no
/// local file target in v0.1, so it copies instead — the stub reports
/// that honestly rather than pretending).
class ExportService {
  ExportService._();

  /// The workspace as a pretty-printed JSON document.
  static String workspaceJson(Workspace workspace) =>
      const JsonEncoder.withIndent('  ').convert(workspace.toJson());

  /// Suggested filename for an export.
  static String fileName() {
    final now = DateTime.now();
    final stamp =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return 'parallel-export-$stamp.json';
  }

  /// Copies the export JSON to the clipboard.
  static Future<void> copyToClipboard(Workspace workspace) async {
    await Clipboard.setData(
      ClipboardData(text: workspaceJson(workspace)),
    );
  }

  /// Saves the export to a file on native platforms. Returns the saved
  /// path. On web this throws [UnsupportedError] — the UI falls back to
  /// clipboard copy.
  static Future<String> saveToFile(Workspace workspace) =>
      platform_export.saveExportFile(workspaceJson(workspace), fileName());

  /// Whether this platform can save a file.
  static bool get canSaveFile => platform_export.canSaveFile;
}
