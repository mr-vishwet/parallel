import 'package:flutter_test/flutter_test.dart';
import 'package:parallel/engine/branch_engine.dart';
import 'package:parallel/engine/demo_data.dart';
import 'package:parallel/engine/models.dart';

void main() {
  late Project harbour;

  setUp(() {
    harbour = DemoData.seedWorkspace().projects.first;
  });

  Branch mainBranch() => harbour.branchById('main')!;
  Branch cinematic() => harbour.branchById('cinematic')!;

  group('nextSnapshotId', () {
    test('continues the sequence on main', () {
      expect(BranchEngine.nextSnapshotId(mainBranch()), 'm10');
    });

    test('starts at 1 on a fresh branch', () {
      const fresh = Branch(
        id: 'festival-cut',
        name: 'festival-cut',
        tagline: '',
        color: 0xFF60A5FA,
        prefix: 'f',
        runtimeSeconds: 228,
      );
      expect(BranchEngine.nextSnapshotId(fresh), 'f1');
    });
  });

  group('createBranch', () {
    test('forks from a snapshot, copying a pointer not data', () {
      final branch = BranchEngine.createBranch(
        project: harbour,
        name: 'festival-cut',
        forkFromSnapshotId: 'm7',
      );
      expect(branch.id, 'festival-cut');
      expect(branch.prefix, 'f');
      expect(branch.forkedFrom, 'm7');
      expect(branch.snapshots, isEmpty);
      expect(branch.runtimeSeconds, 228);
    });

    test('rejects an empty name', () {
      expect(
        () => BranchEngine.createBranch(
          project: harbour,
          name: '  ',
          forkFromSnapshotId: 'm7',
        ),
        throwsArgumentError,
      );
    });

    test('rejects a duplicate name', () {
      expect(
        () => BranchEngine.createBranch(
          project: harbour,
          name: 'cinematic',
          forkFromSnapshotId: 'm7',
        ),
        throwsArgumentError,
      );
    });

    test('rejects an unknown fork snapshot', () {
      expect(
        () => BranchEngine.createBranch(
          project: harbour,
          name: 'festival-cut',
          forkFromSnapshotId: 'm99',
        ),
        throwsArgumentError,
      );
    });

    test('prefix falls back when the first letter is taken', () {
      final branch = BranchEngine.createBranch(
        project: harbour,
        name: 'minimal-2',
        forkFromSnapshotId: 'm7',
      );
      // 'm' is taken by main, 'i' is free.
      expect(branch.prefix, 'i');
    });
  });

  group('takeSnapshot', () {
    test('appends with the next id and the parent linked', () {
      final updated = BranchEngine.takeSnapshot(
        branch: mainBranch(),
        message: 'Trimmed the credits',
        author: 'Mara',
      );
      expect(updated.snapshots.length, 10);
      expect(updated.latest!.id, 'm10');
      expect(updated.latest!.message, 'Trimmed the credits');
      expect(updated.latest!.parentId, 'm9');
    });

    test('does not mutate the original branch', () {
      final before = mainBranch();
      BranchEngine.takeSnapshot(
        branch: before,
        message: 'Trimmed the credits',
        author: 'Mara',
      );
      expect(before.snapshots.length, 9);
      expect(before.latest!.id, 'm9');
    });

    test('moves the runtime by the changes deltas', () {
      final updated = BranchEngine.takeSnapshot(
        branch: mainBranch(),
        message: 'Held the ending',
        author: 'Mara',
        changes: const [
          Change(
            id: 'x-0',
            title: 'Ending',
            detail: 'Held 6 seconds longer',
            meta: 'Scene 13',
            runtimeDeltaSeconds: 6,
          ),
        ],
      );
      expect(updated.runtimeSeconds, 234);
    });

    test('rejects an empty message', () {
      expect(
        () => BranchEngine.takeSnapshot(
          branch: mainBranch(),
          message: '  ',
          author: 'Mara',
        ),
        throwsArgumentError,
      );
    });
  });

  group('restore', () {
    test('restoreScope names what returns and what stays changed', () {
      final m6 = mainBranch().snapshots[3];
      expect(m6.id, 'm6');
      final scope = BranchEngine.restoreScope(
        branch: mainBranch(),
        snapshot: m6,
      );
      expect(scope.returns.length, 1);
      expect(scope.staysChanged.map((s) => s.id), ['m9', 'm8', 'm7']);
    });

    test('restore appends a new snapshot and rewrites nothing', () {
      final before = mainBranch();
      final m6 = before.snapshots[3];
      final updated = BranchEngine.restoreSnapshot(
        branch: before,
        snapshot: m6,
        author: 'Mara',
      );
      expect(updated.latest!.id, 'm10');
      expect(updated.latest!.message, 'Restored the second voiceover pass');
      expect(updated.latest!.restores, 'm6');
      // The originals are untouched.
      expect(before.snapshots.length, 9);
      expect(updated.snapshots[1].id, 'm9');
      expect(updated.snapshots[4].id, 'm6');
      expect(updated.snapshots[4].message, 'Cut the second voiceover pass');
    });
  });

  group('merge', () {
    test('planMerge blocks landing while a conflict is unresolved', () {
      final diff = BranchEngine.diff(
        source: cinematic(),
        target: mainBranch(),
      );
      final plan = BranchEngine.planMerge(
        diffResult: diff,
        selectedIds: BranchEngine.defaultSelection(diff.changes),
        conflictResolution: const {},
      );
      expect(plan.conflictsResolved, isFalse);
      expect(plan.canLand, isFalse);
    });

    test('planMerge lands once the conflict is resolved', () {
      final diff = BranchEngine.diff(
        source: cinematic(),
        target: mainBranch(),
      );
      final plan = BranchEngine.planMerge(
        diffResult: diff,
        selectedIds: BranchEngine.defaultSelection(diff.changes),
        conflictResolution: const {'c1-0': 'source'},
      );
      expect(plan.canLand, isTrue);
      expect(plan.applied.map((c) => c.id), ['c1-0', 'c2-0', 'c3-0']);
      expect(plan.leftBehind.map((c) => c.id), ['c4-0', 'c4-1']);
      expect(plan.runtimeDeltaSeconds, 2);
    });

    test('resolving to target leaves the change behind', () {
      final diff = BranchEngine.diff(
        source: cinematic(),
        target: mainBranch(),
      );
      final plan = BranchEngine.planMerge(
        diffResult: diff,
        selectedIds: BranchEngine.defaultSelection(diff.changes),
        conflictResolution: const {'c1-0': 'target'},
      );
      expect(plan.canLand, isTrue);
      expect(plan.applied.map((c) => c.id), ['c2-0', 'c3-0']);
      expect(plan.leftBehind.map((c) => c.id), ['c1-0', 'c4-0', 'c4-1']);
    });

    test('applyMerge creates the merge snapshot and leaves source intact', () {
      final diff = BranchEngine.diff(
        source: cinematic(),
        target: mainBranch(),
      );
      final plan = BranchEngine.planMerge(
        diffResult: diff,
        selectedIds: BranchEngine.defaultSelection(diff.changes),
        conflictResolution: const {'c1-0': 'source'},
      );
      final updated = BranchEngine.applyMerge(
        target: mainBranch(),
        source: cinematic(),
        plan: plan,
        author: 'Mara',
      );
      expect(updated.latest!.id, 'm10');
      expect(updated.latest!.message, 'Merged cinematic into main');
      expect(updated.latest!.mergeOf, 'cinematic');
      expect(updated.runtimeSeconds, 230);
      // The source branch is untouched — the unpicked changes stay on it.
      expect(cinematic().snapshots.length, 4);
    });

    test('applyMerge refuses a plan that cannot land', () {
      final diff = BranchEngine.diff(
        source: cinematic(),
        target: mainBranch(),
      );
      final plan = BranchEngine.planMerge(
        diffResult: diff,
        selectedIds: BranchEngine.defaultSelection(diff.changes),
        conflictResolution: const {},
      );
      expect(
        () => BranchEngine.applyMerge(
          target: mainBranch(),
          source: cinematic(),
          plan: plan,
          author: 'Mara',
        ),
        throwsStateError,
      );
    });
  });

  group('search', () {
    test('voiceover finds 3 snapshots across main and minimal', () {
      final hits = BranchEngine.searchSnapshots(harbour, 'voiceover');
      expect(hits.map((h) => h.snapshot.id), ['m6', 'n2', 'm2']);
      expect(hits.map((h) => h.branchId).toSet(), {'main', 'minimal'});
    });

    test('search is case-insensitive and matches ids', () {
      expect(
        BranchEngine.searchSnapshots(harbour, 'M9').map((h) => h.snapshot.id),
        ['m9'],
      );
      expect(
        BranchEngine.searchSnapshots(harbour, 'DEV').map((h) => h.snapshot.id),
        containsAll(['m7', 'm4']),
      );
    });

    test('empty query returns nothing', () {
      expect(BranchEngine.searchSnapshots(harbour, '  '), isEmpty);
    });
  });

  group('sceneLastChanged', () {
    test('computes the last-changing branch per scene', () {
      final marks = BranchEngine.sceneLastChanged(harbour);
      expect(marks[1], 'cinematic');
      expect(marks[6], 'cinematic');
      expect(marks[10], 'experimental');
      expect(marks[12], 'main');
      expect(marks[13], 'main');
    });
  });
}
