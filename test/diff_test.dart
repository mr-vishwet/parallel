import 'package:flutter_test/flutter_test.dart';
import 'package:parallel/engine/branch_engine.dart';
import 'package:parallel/engine/demo_data.dart';
import 'package:parallel/engine/models.dart';

void main() {
  group('cinematic vs main (demo canon)', () {
    late Project harbour;

    setUp(() {
      harbour = DemoData.seedWorkspace().projects.first;
    });

    test('the diff is 5 changes, oldest first', () {
      final diff = BranchEngine.diff(
        source: harbour.branchById('cinematic')!,
        target: harbour.branchById('main')!,
      );
      expect(diff.forkSnapshotId, 'm3');
      expect(
        diff.changes.map((c) => c.id),
        ['c1-0', 'c2-0', 'c3-0', 'c4-0', 'c4-1'],
      );
      expect(diff.changes.first.title, 'Opening shot');
    });

    test('two conflicts: the opening shot and the voiceover', () {
      final diff = BranchEngine.diff(
        source: harbour.branchById('cinematic')!,
        target: harbour.branchById('main')!,
      );
      // c1-0 is the seeded conflict (the opening shot). c4-1 is detected
      // by the engine: main cut the scene-4 voiceover in m6 while
      // cinematic kept and trimmed it in c4 — the same scene, the same
      // kind, after the fork. Both are real conflicts.
      expect(diff.conflicts.map((c) => c.id), ['c1-0', 'c4-1']);
      expect(
        diff.conflicts.first.conflictNote,
        contains('Dev reframed the boathouse'),
      );
      expect(
        diff.conflicts.last.conflictNote,
        contains('voiceover'),
      );
    });

    test('default selection is 3 of 5 (runtime and voiceover unticked)', () {
      final diff = BranchEngine.diff(
        source: harbour.branchById('cinematic')!,
        target: harbour.branchById('main')!,
      );
      final selected = BranchEngine.defaultSelection(diff.changes);
      expect(selected, {'c1-0', 'c2-0', 'c3-0'});
    });

    test('the full runtime delta is +14s', () {
      final diff = BranchEngine.diff(
        source: harbour.branchById('cinematic')!,
        target: harbour.branchById('main')!,
      );
      expect(diff.runtimeDeltaSeconds, 14);
    });
  });

  group('generic conflict detection', () {
    late Branch target;
    late Branch source;

    Change shot(String id, int scene) => Change(
          id: id,
          title: 'Opening shot',
          detail: 'Changed the opening',
          meta: 'Scene $scene',
          scenes: [scene],
          kind: 'shot',
        );

    setUp(() {
      // Target: fork point f0, then a post-fork shot change on scene 1.
      target = Branch(
        id: 'main',
        name: 'main',
        tagline: '',
        color: 0xFFB03220,
        prefix: 'm',
        runtimeSeconds: 100,
        snapshots: [
          Snapshot(
            id: 'm2',
            message: 'Reframed the opening',
            author: 'Dev',
            createdAt: DateTime(2026, 1, 2),
            branchId: 'main',
            changes: [shot('m2-0', 1)],
            parentId: 'm1',
          ),
          Snapshot(
            id: 'm1',
            message: 'First assembly',
            author: 'Mara',
            createdAt: DateTime(2026, 1, 1),
            branchId: 'main',
            changes: const [],
          ),
        ],
      );
    });

    test('same scene + same kind after the fork conflicts', () {
      source = Branch(
        id: 'alt',
        name: 'alt',
        tagline: '',
        color: 0xFFFBBF24,
        prefix: 'a',
        forkedFrom: 'm1',
        runtimeSeconds: 100,
        snapshots: [
          Snapshot(
            id: 'a1',
            message: 'Opened on the harbour',
            author: 'Mara',
            createdAt: DateTime(2026, 1, 3),
            branchId: 'alt',
            changes: [shot('a1-0', 1)],
          ),
        ],
      );
      final diff = BranchEngine.diff(source: source, target: target);
      expect(diff.conflicts.map((c) => c.id), ['a1-0']);
    });

    test('same scene + different kind does not conflict', () {
      source = Branch(
        id: 'alt',
        name: 'alt',
        tagline: '',
        color: 0xFFFBBF24,
        prefix: 'a',
        forkedFrom: 'm1',
        runtimeSeconds: 100,
        snapshots: [
          Snapshot(
            id: 'a1',
            message: 'Warmed the grade on scene 1',
            author: 'Mara',
            createdAt: DateTime(2026, 1, 3),
            branchId: 'alt',
            changes: const [
              Change(
                id: 'a1-0',
                title: 'Grade',
                detail: 'Warmed the grade',
                meta: 'Scene 1',
                scenes: [1],
                kind: 'grade',
              ),
            ],
          ),
        ],
      );
      final diff = BranchEngine.diff(source: source, target: target);
      expect(diff.conflicts, isEmpty);
    });

    test('same kind + different scene does not conflict', () {
      source = Branch(
        id: 'alt',
        name: 'alt',
        tagline: '',
        color: 0xFFFBBF24,
        prefix: 'a',
        forkedFrom: 'm1',
        runtimeSeconds: 100,
        snapshots: [
          Snapshot(
            id: 'a1',
            message: 'Replaced the rooftop take',
            author: 'Mara',
            createdAt: DateTime(2026, 1, 3),
            branchId: 'alt',
            changes: [shot('a1-0', 12)],
          ),
        ],
      );
      final diff = BranchEngine.diff(source: source, target: target);
      expect(diff.conflicts, isEmpty);
    });

    test('a change before the fork point does not conflict', () {
      // Source forked from m2 (after the target's shot change), so the
      // target has nothing newer than the fork to conflict with.
      source = Branch(
        id: 'alt',
        name: 'alt',
        tagline: '',
        color: 0xFFFBBF24,
        prefix: 'a',
        forkedFrom: 'm2',
        runtimeSeconds: 100,
        snapshots: [
          Snapshot(
            id: 'a1',
            message: 'Opened on the harbour',
            author: 'Mara',
            createdAt: DateTime(2026, 1, 3),
            branchId: 'alt',
            changes: [shot('a1-0', 1)],
          ),
        ],
      );
      final diff = BranchEngine.diff(source: source, target: target);
      expect(diff.conflicts, isEmpty);
    });

    test('an empty source branch diffs to no changes', () {
      source = const Branch(
        id: 'alt',
        name: 'alt',
        tagline: '',
        color: 0xFFFBBF24,
        prefix: 'a',
        forkedFrom: 'm1',
        runtimeSeconds: 100,
      );
      final diff = BranchEngine.diff(source: source, target: target);
      expect(diff.changes, isEmpty);
      expect(diff.conflicts, isEmpty);
    });
  });
}
