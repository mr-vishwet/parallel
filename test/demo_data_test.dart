import 'package:flutter_test/flutter_test.dart';
import 'package:parallel/engine/demo_data.dart';

void main() {
  group('seeded demo workspace (V7 canon)', () {
    final workspace = DemoData.seedWorkspace();

    test('3 projects, 7 branches, 34 snapshots', () {
      expect(workspace.projects.length, 3);
      expect(workspace.branchCount, 7);
      expect(workspace.snapshotCount, 34);
    });

    test('Harbour Light: 4 branches, 21 snapshots, 14 scenes', () {
      final harbour = workspace.projects.first;
      expect(harbour.name, 'Harbour Light');
      expect(harbour.branches.length, 4);
      expect(harbour.snapshotCount, 21);
      expect(harbour.scenes.length, 14);
      expect(harbour.isDemo, isTrue);
      expect(workspace.openProjectId, 'harbour-light');
    });

    test('branch snapshot counts match the canon', () {
      final harbour = workspace.projects.first;
      expect(harbour.branchById('main')!.snapshotCount, 9);
      expect(harbour.branchById('cinematic')!.snapshotCount, 4);
      expect(harbour.branchById('minimal')!.snapshotCount, 3);
      expect(harbour.branchById('experimental')!.snapshotCount, 5);
    });

    test('runtimes match the canon', () {
      final harbour = workspace.projects.first;
      expect(harbour.branchById('main')!.runtimeSeconds, 228); // 3:48
      expect(harbour.branchById('cinematic')!.runtimeSeconds, 242); // 4:02
      expect(harbour.branchById('minimal')!.runtimeSeconds, 211); // 3:31
      expect(harbour.branchById('experimental')!.runtimeSeconds, 236); // 3:56
    });

    test('fork points match the canon', () {
      final harbour = workspace.projects.first;
      expect(harbour.branchById('main')!.forkedFrom, isNull);
      expect(harbour.branchById('cinematic')!.forkedFrom, 'm3');
      expect(harbour.branchById('minimal')!.forkedFrom, 'm5');
      expect(harbour.branchById('experimental')!.forkedFrom, 'm7');
    });

    test('the cinematic merge is in review', () {
      final harbour = workspace.projects.first;
      expect(harbour.mergeInReviewSource, 'cinematic');
      expect(workspace.mergesInReview, 1);
    });

    test('Launch Teaser and Field Notes fill out the totals', () {
      final teaser = workspace.projects[1];
      expect(teaser.name, 'Launch Teaser');
      expect(teaser.branches.length, 2);
      expect(teaser.snapshotCount, 8);
      final notes = workspace.projects[2];
      expect(notes.name, 'Field Notes');
      expect(notes.branches.length, 1);
      expect(notes.snapshotCount, 5);
    });

    test('snapshot ids are unique within each project', () {
      for (final project in workspace.projects) {
        final ids = <String>{};
        for (final branch in project.branches) {
          for (final snap in branch.snapshots) {
            expect(ids.add(snap.id), isTrue,
                reason: 'duplicate snapshot id ${snap.id}');
          }
        }
      }
    });

    test('every snapshot carries message, author and time', () {
      for (final project in workspace.projects) {
        for (final branch in project.branches) {
          for (final snap in branch.snapshots) {
            expect(snap.message.isNotEmpty, isTrue);
            expect(snap.author.isNotEmpty, isTrue);
            expect(
              snap.createdAt.isAfter(DateTime.now()),
              isFalse,
              reason: '${snap.id} is dated in the future',
            );
          }
        }
      }
    });

    test('activity is seeded newest first', () {
      final activity = workspace.activity;
      expect(activity.isNotEmpty, isTrue);
      for (var i = 1; i < activity.length; i++) {
        expect(
          activity[i].at.isAfter(activity[i - 1].at),
          isFalse,
          reason: 'activity is not newest-first',
        );
      }
    });
  });
}
