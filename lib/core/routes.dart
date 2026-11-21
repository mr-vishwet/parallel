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
  /// The /welcome route.
  static const String welcome = '/welcome';
  /// The /guest route.
  static const String guest = '/guest';
  /// The /sign-in route.
  static const String signIn = '/sign-in';
  /// The /create-account route.
  static const String createAccount = '/create-account';
  /// The /verify route.
  static const String verify = '/verify';
  /// The /upgrade route.
  static const String upgrade = '/upgrade';
  /// The /migrate route.
  static const String migrate = '/migrate';
  /// The /account route.
  static const String account = '/account';
  /// The /connected route.
  static const String connected = '/connected';
  /// The /data-controls route.
  static const String dataControls = '/data-controls';

  /// The /projects route.
  static const String projects = '/projects';
  /// The /branch-map route.
  static const String branchMap = '/branch-map';
  /// The /branch route.
  static const String branchDetail = '/branch';
  /// The /new-branch route.
  static const String newBranch = '/new-branch';
  /// The /snapshots route.
  static const String snapshots = '/snapshots';
  /// The /snapshot route.
  static const String snapshotDetail = '/snapshot';
  /// The /diff route.
  static const String diff = '/diff';
  /// The /change route.
  static const String changeDetail = '/change';
  /// The /compare route.
  static const String compare = '/compare';
  /// The /restore route.
  static const String restore = '/restore';
  /// The /restored route.
  static const String restored = '/restored';
  /// The /merge route.
  static const String merge = '/merge';
  /// The /conflict route.
  static const String conflict = '/conflict';
  /// The /merged route.
  static const String merged = '/merged';
  /// The /timeline route.
  static const String timeline = '/timeline';
  /// The /search route.
  static const String search = '/search';
  /// The /activity route.
  static const String activity = '/activity';
  /// The /settings route.
  static const String settings = '/settings';
}

/// Arguments for [Routes.branchDetail]: which branch of the open project.
class BranchArgs {
  /// Creates a [BranchArgs].
  const BranchArgs(this.branchId);

  /// The branch id.
  final String branchId;
}

/// Arguments for [Routes.newBranch]: optional pre-selected fork point.
class NewBranchArgs {
  /// Creates a [NewBranchArgs].
  const NewBranchArgs({this.forkFromSnapshotId});

  /// The snapshot id to fork from, if pre-selected.
  final String? forkFromSnapshotId;
}

/// Arguments for [Routes.snapshots]: which branch to list (default main).
class SnapshotsArgs {
  /// Creates a [SnapshotsArgs].
  const SnapshotsArgs({this.branchId = 'main'});

  /// The branch id.
  final String branchId;
}

/// Arguments for [Routes.snapshotDetail].
class SnapshotArgs {
  /// Creates a [SnapshotArgs].
  const SnapshotArgs({required this.branchId, required this.snapshotId});

  /// The branch id.
  final String branchId;
  /// The snapshot id.
  final String snapshotId;
}

/// Arguments for [Routes.diff] and [Routes.merge]: the two branches.
class DiffArgs {
  /// Creates a [DiffArgs].
  const DiffArgs({required this.sourceId, required this.targetId});

  /// The source id.
  final String sourceId;
  /// The target id.
  final String targetId;
}

/// Arguments for [Routes.changeDetail]: a change inside a diff.
class ChangeArgs {
  /// Creates a [ChangeArgs].
  const ChangeArgs({
    required this.changeId,
    required this.sourceId,
    required this.targetId,
  });

  /// The change id.
  final String changeId;
  /// The source id.
  final String sourceId;
  /// The target id.
  final String targetId;
}

/// Arguments for [Routes.restore].
class RestoreArgs {
  /// Creates a [RestoreArgs].
  const RestoreArgs({required this.branchId, required this.snapshotId});

  /// The branch id.
  final String branchId;
  /// The snapshot id.
  final String snapshotId;
}

/// Arguments for [Routes.restored]: the snapshot the restore created.
class RestoredArgs {
  /// Creates a [RestoredArgs].
  const RestoredArgs({required this.branchId, required this.snapshotId});

  /// The branch id.
  final String branchId;
  /// The snapshot id.
  final String snapshotId;
}

/// Arguments for [Routes.merged]: the snapshot the merge created.
class MergedArgs {
  /// Creates a [MergedArgs].
  const MergedArgs({
    required this.branchId,
    required this.snapshotId,
    required this.sourceId,
  });

  /// The branch id.
  final String branchId;
  /// The snapshot id.
  final String snapshotId;
  /// The source id.
  final String sourceId;
}

/// Arguments for [Routes.timeline]: optionally highlight one scene.
class TimelineArgs {
  /// Creates a [TimelineArgs].
  const TimelineArgs({this.highlightScene});

  /// The scene to highlight, if any.
  final int? highlightScene;
}

/// Arguments for [Routes.upgrade]: what the guest was trying to do.
class UpgradeArgs {
  /// Creates an [UpgradeArgs].
  const UpgradeArgs({required this.action});

  /// Human phrase, e.g. "branch this project".
  final String action;
}
