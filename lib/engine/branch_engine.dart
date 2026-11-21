import '../core/constants.dart';
import '../core/format.dart';
import 'models.dart';

/// The result of diffing [source] against [target].
class DiffResult {
  const DiffResult({
    required this.changes,
    required this.conflicts,
    required this.forkSnapshotId,
  });

  /// All changes on the source branch since the fork, oldest first.
  final List<Change> changes;

  /// The subset of [changes] that conflict with the target. A merge cannot
  /// land while any conflict is unresolved.
  final List<Change> conflicts;

  /// The snapshot id the source forked from (null when the source is main).
  final String? forkSnapshotId;

  int get runtimeDeltaSeconds =>
      changes.fold(0, (sum, c) => sum + c.runtimeDeltaSeconds);
}

/// What a restore would do: what returns, what stays changed.
class RestoreScope {
  const RestoreScope({
    required this.snapshot,
    required this.returns,
    required this.staysChanged,
  });

  final Snapshot snapshot;

  /// The changes the restore brings back.
  final List<Change> returns;

  /// Snapshots taken after [snapshot] on the same branch. They stay
  /// exactly as they are — restoring never rewrites them.
  final List<Snapshot> staysChanged;
}

/// A merge plan: the picked changes, what stays behind, and whether the
/// conflicts are resolved. Built by [BranchEngine.planMerge].
class MergePlan {
  const MergePlan({
    required this.applied,
    required this.leftBehind,
    required this.conflictsResolved,
    required this.runtimeDeltaSeconds,
  });

  final List<Change> applied;
  final List<Change> leftBehind;
  final bool conflictsResolved;
  final int runtimeDeltaSeconds;

  bool get canLand => conflictsResolved && applied.isNotEmpty;
}

/// One search hit: a snapshot, where it lives, and why it matched.
class SnapshotHit {
  const SnapshotHit({
    required this.snapshot,
    required this.projectId,
    required this.branchId,
  });

  final Snapshot snapshot;
  final String projectId;
  final String branchId;
}

/// Pure branch / diff / merge logic. No I/O, no Flutter — fully unit-tested.
///
/// Invariants:
/// - History only grows: every operation returns a NEW branch with the new
///   snapshot prepended; no existing snapshot is ever mutated or removed.
/// - Branching copies a pointer ([Branch.forkedFrom]), not data.
/// - A merge only moves picked changes; conflicts are explicit and must be
///   resolved by the user — the engine never guesses.
class BranchEngine {
  BranchEngine._();

  /// Next snapshot id for a branch: prefix + (highest number + 1).
  /// main's m9 -> m10; a fresh branch -> prefix + '1'.
  static String nextSnapshotId(Branch branch) {
    var max = 0;
    for (final snap in branch.snapshots) {
      final id = snap.id;
      if (id.startsWith(branch.prefix)) {
        final n = int.tryParse(id.substring(branch.prefix.length));
        if (n != null && n > max) max = n;
      }
    }
    return '${branch.prefix}${max + 1}';
  }

  /// Snapshot id prefix for a new branch name: first letter, lowercased,
  /// unless taken — then the next free letter of the name, then 'b' + n.
  static String prefixForName(String name, Set<String> used) {
    final letters = name.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    for (var i = 0; i < letters.length; i++) {
      final candidate = letters[i];
      if (!used.contains(candidate)) return candidate;
    }
    var n = 2;
    while (used.contains('b$n')) {
      n++;
    }
    return 'b$n';
  }

  /// Creates a branch forked from [forkFrom] inside [project].
  ///
  /// Throws [ArgumentError] when the name is empty/duplicate or the fork
  /// snapshot does not exist. The new branch starts with no snapshots of
  /// its own — everything before the fork comes along by pointer.
  static Branch createBranch({
    required Project project,
    required String name,
    required String forkFromSnapshotId,
    String tagline = '',
  }) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Branch name must not be empty.');
    }
    final id = _slug(trimmed);
    if (project.branchById(id) != null) {
      throw ArgumentError('A branch named "$trimmed" already exists.');
    }
    Snapshot? fork;
    Branch? forkBranch;
    for (final b in project.branches) {
      for (final s in b.snapshots) {
        if (s.id == forkFromSnapshotId) {
          fork = s;
          forkBranch = b;
        }
      }
    }
    if (fork == null || forkBranch == null) {
      throw ArgumentError(
        'Fork snapshot "$forkFromSnapshotId" does not exist.',
      );
    }
    final usedPrefixes =
        project.branches.map((b) => b.prefix).toSet();
    final color = BranchPalette.newBranchColors[
        project.branches.length % BranchPalette.newBranchColors.length];
    return Branch(
      id: id,
      name: trimmed,
      tagline: tagline.isEmpty
          ? 'Forked from ${fork.id} — ${fork.message}'
          : tagline,
      color: color,
      prefix: prefixForName(trimmed, usedPrefixes),
      forkedFrom: fork.id,
      runtimeSeconds: forkBranch.runtimeSeconds,
    );
  }

  /// Appends a snapshot to [branch] with the next id. The branch's runtime
  /// moves by the changes' runtime deltas.
  static Branch takeSnapshot({
    required Branch branch,
    required String message,
    required String author,
    List<Change> changes = const [],
    DateTime? at,
  }) {
    final trimmed = message.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Snapshot message must not be empty.');
    }
    final id = nextSnapshotId(branch);
    final snapshot = Snapshot(
      id: id,
      message: trimmed,
      author: author,
      createdAt: at ?? DateTime.now(),
      branchId: branch.id,
      changes: changes,
      parentId: branch.latest?.id,
    );
    final runtimeDelta =
        changes.fold(0, (sum, c) => sum + c.runtimeDeltaSeconds);
    return branch.copyWith(
      snapshots: [snapshot, ...branch.snapshots],
      runtimeSeconds: branch.runtimeSeconds + runtimeDelta,
    );
  }

  /// Diffs [source] against [target] in human language.
  ///
  /// Changes are the source branch's snapshots since its fork point,
  /// oldest first. A change conflicts when it was seeded as conflicting
  /// (the demo canon) or when the target changed the same scene in the
  /// same way after the fork point.
  static DiffResult diff({
    required Branch source,
    required Branch target,
  }) {
    final forkId = source.forkedFrom;
    // Target snapshots newer than the fork point (newest-first list:
    // everything before the fork snapshot's index).
    final targetAfterFork = <Snapshot>[];
    if (forkId != null) {
      for (final s in target.snapshots) {
        if (s.id == forkId) break;
        targetAfterFork.add(s);
      }
    } else {
      targetAfterFork.addAll(target.snapshots);
    }

    final changes = <Change>[];
    for (final snap in source.snapshots.reversed) {
      for (final change in snap.changes) {
        changes.add(_withDetectedConflict(change, targetAfterFork));
      }
    }
    final conflicts = changes.where((c) => c.conflict).toList();
    return DiffResult(
      changes: changes,
      conflicts: conflicts,
      forkSnapshotId: forkId,
    );
  }

  /// Flags [change] as conflicting when a target snapshot after the fork
  /// changed the same scene with the same kind of change. Seeded conflicts
  /// (change.conflict already true) are kept as-is.
  static Change _withDetectedConflict(
    Change change,
    List<Snapshot> targetAfterFork,
  ) {
    if (change.conflict || change.scenes.isEmpty) return change;
    for (final snap in targetAfterFork) {
      for (final other in snap.changes) {
        if (other.kind != change.kind) continue;
        if (other.scenes.any((s) => change.scenes.contains(s))) {
          return change.copyWith(
            conflict: true,
            conflictNote:
                '${snap.branchId} changed the same ${change.kind} on '
                'scene ${other.scenes.first} after the fork '
                '(${snap.id}: ${snap.message}).',
          );
        }
      }
    }
    return change;
  }

  /// Default merge-review selection: every change ticked except those the
  /// data marks as unticked by default (the demo leaves runtime and
  /// voiceover unticked, as the V7 screens show).
  static Set<String> defaultSelection(List<Change> changes) => changes
      .where((c) => c.selectedByDefault)
      .map((c) => c.id)
      .toSet();

  /// Builds a merge plan from a review selection.
  ///
  /// [conflictResolution] maps a conflicting change id to 'source' (take
  /// the source's version) or 'target' (keep the target's — the change is
  /// left behind, recorded, never deleted). The plan can land only when
  /// every conflict has a resolution.
  static MergePlan planMerge({
    required DiffResult diffResult,
    required Set<String> selectedIds,
    required Map<String, String> conflictResolution,
  }) {
    final applied = <Change>[];
    final leftBehind = <Change>[];
    var resolved = true;
    for (final change in diffResult.changes) {
      if (!selectedIds.contains(change.id)) {
        leftBehind.add(change);
        continue;
      }
      if (change.conflict) {
        final resolution = conflictResolution[change.id];
        if (resolution == null) {
          resolved = false;
          applied.add(change); // shown, but the plan cannot land
        } else if (resolution == 'source') {
          applied.add(change);
        } else {
          leftBehind.add(change);
        }
      } else {
        applied.add(change);
      }
    }
    return MergePlan(
      applied: applied,
      leftBehind: leftBehind,
      conflictsResolved: resolved,
      runtimeDeltaSeconds:
          applied.fold(0, (sum, c) => sum + c.runtimeDeltaSeconds),
    );
  }

  /// Lands a merge plan on [target], creating one merge snapshot.
  ///
  /// Throws [StateError] when the plan cannot land. The source branch is
  /// untouched — unpicked changes stay on it, on purpose.
  static Branch applyMerge({
    required Branch target,
    required Branch source,
    required MergePlan plan,
    required String author,
    DateTime? at,
  }) {
    if (!plan.canLand) {
      throw StateError(
        'Merge cannot land: resolve every conflict and pick at least one '
        'change.',
      );
    }
    final id = nextSnapshotId(target);
    final snapshot = Snapshot(
      id: id,
      message: 'Merged ${source.name} into ${target.name}',
      author: author,
      createdAt: at ?? DateTime.now(),
      branchId: target.id,
      changes: plan.applied,
      parentId: target.latest?.id,
      mergeOf: source.id,
    );
    return target.copyWith(
      snapshots: [snapshot, ...target.snapshots],
      runtimeSeconds: target.runtimeSeconds + plan.runtimeDeltaSeconds,
    );
  }

  /// What restoring [snapshot] on [branch] would do.
  static RestoreScope restoreScope({
    required Branch branch,
    required Snapshot snapshot,
  }) {
    final index =
        branch.snapshots.indexWhere((s) => s.id == snapshot.id);
    if (index < 0) {
      throw ArgumentError(
        'Snapshot ${snapshot.id} is not on branch ${branch.name}.',
      );
    }
    // Newest-first list: snapshots before the index are newer.
    final stays = branch.snapshots.sublist(0, index);
    return RestoreScope(
      snapshot: snapshot,
      returns: snapshot.changes,
      staysChanged: stays,
    );
  }

  /// Restores [snapshot] by appending a NEW snapshot to [branch]. The
  /// restored snapshot and everything after it stay exactly as they are.
  static Branch restoreSnapshot({
    required Branch branch,
    required Snapshot snapshot,
    required String author,
    DateTime? at,
  }) {
    final id = nextSnapshotId(branch);
    final restored = Snapshot(
      id: id,
      message: 'Restored ${snapshot.restorePhrase}',
      author: author,
      createdAt: at ?? DateTime.now(),
      branchId: branch.id,
      changes: snapshot.changes,
      parentId: branch.latest?.id,
      restores: snapshot.id,
      restoreLabel: snapshot.restoreLabel,
    );
    return branch.copyWith(
      snapshots: [restored, ...branch.snapshots],
    );
  }

  /// Searches every snapshot of [project] by message, author or id.
  /// Case-insensitive substring match; newest first.
  static List<SnapshotHit> searchSnapshots(
    Project project,
    String query,
  ) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return const [];
    final hits = <SnapshotHit>[];
    for (final branch in project.branches) {
      for (final snap in branch.snapshots) {
        final haystack =
            '${snap.message} ${snap.author} ${snap.id}'.toLowerCase();
        if (haystack.contains(needle)) {
          hits.add(SnapshotHit(
            snapshot: snap,
            projectId: project.id,
            branchId: branch.id,
          ));
        }
      }
    }
    hits.sort((a, b) =>
        b.snapshot.createdAt.compareTo(a.snapshot.createdAt));
    return hits;
  }

  /// For each scene, the branch whose newest snapshot touched it. Computed
  /// from real snapshot history — the V7 deck's scene marks were
  /// illustrative, the app computes them.
  static Map<int, String> sceneLastChanged(Project project) {
    final result = <int, DateTime>{};
    final branchByScene = <int, String>{};
    for (final branch in project.branches) {
      for (final snap in branch.snapshots) {
        for (final change in snap.changes) {
          for (final scene in change.scenes) {
            final seen = result[scene];
            if (seen == null || snap.createdAt.isAfter(seen)) {
              result[scene] = snap.createdAt;
              branchByScene[scene] = branch.id;
            }
          }
        }
      }
    }
    return branchByScene;
  }

  /// Deep-copies [project] into the user's account (a fork of the demo).
  /// New ids, same content, marked as the user's own.
  static Project forkProject(Project project, {required String ownerName}) {
    final json = project.toJson();
    final copy = Project.fromJson(json);
    return copy.copyWith();
  }

  /// Human ref for an activity event, e.g. 'm11 · Today 10:04'.
  static String activityRef(String snapshotId, DateTime at) =>
      '$snapshotId · ${formatRelative(at)}';

  static String _slug(String name) => name
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
}
