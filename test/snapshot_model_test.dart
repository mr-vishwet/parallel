import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:parallel/engine/demo_data.dart';
import 'package:parallel/engine/models.dart';

void main() {
  group('JSON round-trips', () {
    test('Change round-trips', () {
      const change = Change(
        id: 'c1-0',
        title: 'Opening shot',
        detail: 'Opens on the harbour',
        meta: 'Shot replaced · scene 1',
        scenes: [1],
        kind: 'shot',
        runtimeDeltaSeconds: 2,
        conflict: true,
        conflictNote: 'Dev reframed the boathouse.',
        selectedByDefault: true,
      );
      final restored =
          Change.fromJson(jsonDecode(jsonEncode(change.toJson())));
      expect(restored.id, 'c1-0');
      expect(restored.scenes, [1]);
      expect(restored.runtimeDeltaSeconds, 2);
      expect(restored.conflict, isTrue);
      expect(restored.conflictNote, contains('boathouse'));
    });

    test('Snapshot round-trips with its changes', () {
      final snapshot = Snapshot(
        id: 'm9',
        message: 'Locked the ending',
        author: 'Mara',
        createdAt: DateTime(2026, 11, 21, 9, 41),
        branchId: 'main',
        changes: const [
          Change(
            id: 'm9-0',
            title: 'Ending',
            detail: 'Ending held 6 seconds longer',
            meta: 'Scene 13',
            scenes: [13],
          ),
        ],
        parentId: 'm8',
      );
      final restored = Snapshot.fromJson(
        jsonDecode(jsonEncode(snapshot.toJson())) as Map<String, dynamic>,
      );
      expect(restored.id, 'm9');
      expect(restored.createdAt, DateTime(2026, 11, 21, 9, 41));
      expect(restored.changes.length, 1);
      expect(restored.changes.first.scenes, [13]);
      expect(restored.parentId, 'm8');
      expect(restored.isMerge, isFalse);
      expect(restored.isRestore, isFalse);
    });

    test('merge and restore snapshots keep their markers', () {
      final merge = Snapshot(
        id: 'm11',
        message: 'Merged cinematic into main',
        author: 'Mara',
        createdAt: DateTime(2026, 11, 21, 10, 4),
        branchId: 'main',
        mergeOf: 'cinematic',
      );
      final restored = Snapshot.fromJson(
        jsonDecode(jsonEncode(merge.toJson())) as Map<String, dynamic>,
      );
      expect(restored.isMerge, isTrue);
      expect(restored.mergeOf, 'cinematic');

      final restore = Snapshot(
        id: 'm10',
        message: 'Restored the second voiceover pass',
        author: 'Mara',
        createdAt: DateTime(2026, 11, 21, 9, 52),
        branchId: 'main',
        restores: 'm6',
        restoreLabel: 'the second voiceover pass',
      );
      final restored2 = Snapshot.fromJson(
        jsonDecode(jsonEncode(restore.toJson())) as Map<String, dynamic>,
      );
      expect(restored2.isRestore, isTrue);
      expect(restored2.restorePhrase, 'the second voiceover pass');
    });

    test('Branch round-trips newest-first', () {
      final harbour = DemoData.seedWorkspace().projects.first;
      final main = harbour.branchById('main')!;
      final restored = Branch.fromJson(
        jsonDecode(jsonEncode(main.toJson())) as Map<String, dynamic>,
      );
      expect(restored.snapshots.map((s) => s.id),
          main.snapshots.map((s) => s.id));
      expect(restored.runtimeSeconds, 228);
      expect(restored.forkedFrom, isNull);
    });

    test('Workspace round-trips whole', () {
      final workspace = DemoData.seedWorkspace();
      final restored = Workspace.fromJson(
        jsonDecode(jsonEncode(workspace.toJson())) as Map<String, dynamic>,
      );
      expect(restored.projects.length, 3);
      expect(restored.snapshotCount, 34);
      expect(restored.branchCount, 7);
      expect(restored.openProjectId, 'harbour-light');
      expect(
        restored.openProject!.mergeInReviewSource,
        'cinematic',
      );
      expect(restored.activity.length, workspace.activity.length);
    });

    test('AppSettings round-trips', () {
      const settings = AppSettings(
        githubConnected: true,
        reviewLinkOn: true,
        syncBaseUrl: 'http://localhost:8080',
      );
      final restored = AppSettings.fromJson(
        jsonDecode(jsonEncode(settings.toJson())) as Map<String, dynamic>,
      );
      expect(restored.githubConnected, isTrue);
      expect(restored.frameioConnected, isFalse);
      expect(restored.reviewLinkOn, isTrue);
      expect(restored.syncBaseUrl, 'http://localhost:8080');
    });

    test('unknown JSON fields are tolerated', () {
      final snapshot = Snapshot.fromJson({
        'id': 'm1',
        'message': 'First assembly',
        'author': 'Mara',
        'createdAt': '2026-11-17T14:12:00.000',
        'branchId': 'main',
        'futureField': 'ignored',
      });
      expect(snapshot.id, 'm1');
      expect(snapshot.changes, isEmpty);
    });
  });
}
