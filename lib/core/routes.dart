/// Named routes and their argument classes.
///
/// One route per screen concept (30 routes). Each route renders an adaptive
/// layout — the phone layout below [kDesktopBreakpoint] and the desktop
/// shell above it — so the 30 routes cover all 60 V7 inventory screens
/// (30 mobile + 30 web).
library;

/// Route names. The initial route is [projects] when a session exists
/// (signed in or guest) and [welcome] otherwise; see [app.dart].
class Routes {
  static const String welcome = '/welcome';
  static const String guest = '/guest';
  static const String signIn = '/sign-in';
  static const String createAccount = '/create-account';
  static const String verify = '/verify';
  static const String upgrade = '/upgrade';
  static const String migrate = '/migrate';
  static const String account = '/account';
  static const String connected = '/connected';
  static const String dataControls = '/data-controls';

  static const String projects = '/projects';
  static const String branchMap = '/branch-map';
  static const String branchDetail = '/branch';
  static const String newBranch = '/new-branch';
  static const String snapshots = '/snapshots';
  static const String snapshotDetail = '/snapshot';
  static const String diff = '/diff';
  static const String changeDetail = '/change';
  static const String compare = '/compare';
  static const String restore = '/restore';
  static const String restored = '/restored';
  static const String merge = '/merge';
  static const String conflict = '/conflict';
  static const String merged = '/merged';
  static const String timeline = '/timeline';
  static const String search = '/search';
  static const String activity = '/activity';
  static const String settings = '/settings';
}

/// Arguments for [Routes.branchDetail]: which branch of the open project.
class BranchArgs {
  const BranchArgs(this.branchId);

  final String branchId;
}

/// Arguments for [Routes.newBranch]: optional pre-selected fork point.
class NewBranchArgs {
  const NewBranchArgs({this.forkFromSnapshotId});

  final String? forkFromSnapshotId;
}

/// Arguments for [Routes.snapshots]: which branch to list (default main).
class SnapshotsArgs {
  const SnapshotsArgs({this.branchId = 'main'});

  final String branchId;
}

/// Arguments for [Routes.snapshotDetail].
class SnapshotArgs {
  const SnapshotArgs({required this.branchId, required this.snapshotId});

  final String branchId;
  final String snapshotId;
}

/// Arguments for [Routes.diff] and [Routes.merge]: the two branches.
class DiffArgs {
  const DiffArgs({required this.sourceId, required this.targetId});

  final String sourceId;
  final String targetId;
}

/// Arguments for [Routes.changeDetail]: a change inside a diff.
class ChangeArgs {
  const ChangeArgs({
    required this.changeId,
    required this.sourceId,
    required this.targetId,
  });

  final String changeId;
  final String sourceId;
  final String targetId;
}

/// Arguments for [Routes.restore].
class RestoreArgs {
  const RestoreArgs({required this.branchId, required this.snapshotId});

  final String branchId;
  final String snapshotId;
}

/// Arguments for [Routes.restored]: the snapshot the restore created.
class RestoredArgs {
  const RestoredArgs({required this.branchId, required this.snapshotId});

  final String branchId;
  final String snapshotId;
}

/// Arguments for [Routes.merged]: the snapshot the merge created.
class MergedArgs {
  const MergedArgs({
    required this.branchId,
    required this.snapshotId,
    required this.sourceId,
  });

  final String branchId;
  final String snapshotId;
  final String sourceId;
}

/// Arguments for [Routes.timeline]: optionally highlight one scene.
class TimelineArgs {
  const TimelineArgs({this.highlightScene});

  final int? highlightScene;
}

/// Arguments for [Routes.upgrade]: what the guest was trying to do.
class UpgradeArgs {
  const UpgradeArgs({required this.action});

  /// Human phrase, e.g. "branch this project".
  final String action;
}
