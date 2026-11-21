import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';
import '../engine/demo_data.dart';
import '../engine/models.dart';

/// Local-first persistence: the workspace and settings are JSON documents
/// in [SharedPreferences]. No backend in v0.1; the sync sketch in
/// `server/` mirrors this same document shape.
///
/// The store is deliberately boring: one key per document, whole-document
/// reads and writes. A relational store (Drift/SQLite) is the phase-2 item
/// if the document outgrows it.
class WorkspaceStore {
  /// Loads the workspace, seeding the demo content on first launch.
  Future<Workspace> loadWorkspace() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(StoreKeys.workspace);
    if (raw == null || raw.isEmpty) {
      final seeded = DemoData.seedWorkspace();
      await saveWorkspace(seeded);
      return seeded;
    }
    try {
      return Workspace.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // Corrupt document (bad JSON or wrong shape): reseed rather than
      // crash. The old bytes are gone, which is why export exists.
      final seeded = DemoData.seedWorkspace();
      await saveWorkspace(seeded);
      return seeded;
    }
  }

  /// Persists the whole workspace document.
  Future<void> saveWorkspace(Workspace workspace) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StoreKeys.workspace, jsonEncode(workspace.toJson()));
  }

  /// Resets the workspace to the seeded demo content.
  Future<Workspace> resetToDemo() async {
    final seeded = DemoData.seedWorkspace();
    await saveWorkspace(seeded);
    return seeded;
  }

  /// Loads settings, defaulting to all connections off and sync unset.
  Future<AppSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(StoreKeys.settings);
    if (raw == null || raw.isEmpty) return const AppSettings();
    try {
      return AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const AppSettings();
    }
  }

  /// Persists settings.
  Future<void> saveSettings(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StoreKeys.settings, jsonEncode(settings.toJson()));
  }
}
