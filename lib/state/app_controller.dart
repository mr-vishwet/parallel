import 'package:material_ui/material_ui.dart';

import '../engine/branch_engine.dart';
import '../engine/demo_data.dart';
import '../engine/models.dart';
import '../services/auth_service.dart';
import '../services/export_service.dart';
import '../services/store.dart';
import '../services/sync_client.dart';

/// Inherited access to the [AppController] for every screen and widget.
class AppScope extends InheritedWidget {
  /// Creates an [AppScope].
  const AppScope({required this.controller, required super.child, super.key});

  /// The app controller.
  final AppController controller;

  /// Returns the [AppController] for the nearest [AppScope] above [context].
  static AppController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found above this widget.');
    return scope!.controller;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      controller != oldWidget.controller;
}

/// Live state of one merge review: the diff, the ticked changes, and the
/// conflict resolutions. Held in memory by the controller; the review
/// itself is a working state, not persisted history.
class MergeReviewState {
  /// Creates a [MergeReviewState].
  MergeReviewState({
    required this.sourceId,
    required this.targetId,
    required this.diff,
    required this.selectedIds,
    Map<String, String>? resolutions,
  }) : resolutions = resolutions ?? {};

  /// The source id.
  final String sourceId;
  /// The target id.
  final String targetId;
  /// The diff.
  final DiffResult diff;
  /// The selected ids.
  final Set<String> selectedIds;

  /// Conflicting change id -> 'source' (take the source version) or
  /// 'target' (keep the target's; the change stays behind).
  final Map<String, String> resolutions;

  /// The merge plan for the current selection.
  MergePlan get plan => BranchEngine.planMerge(
        diffResult: diff,
        selectedIds: selectedIds,
        conflictResolution: resolutions,
      );

  /// The number of selected changes.
  int get selectedCount => selectedIds.length;

  /// Whether every conflict in the review is resolved.
  bool get allConflictsResolved =>
      diff.conflicts.every((c) => resolutions.containsKey(c.id));
}

/// The whole app's state: workspace, auth, settings, and the live merge
/// review. Every mutation goes through here, persists, and notifies.
///
/// Guest rule (from the V7 auth model): guests view the demo read-only.
/// Branching, merging, restoring, snapshotting and creating all need an
/// account — screens check [canEdit] and route guests to /upgrade.
class AppController extends ChangeNotifier {
  /// Creates an [AppController].
  AppController({WorkspaceStore? store, AuthService? auth})
      : _store = store ?? WorkspaceStore(),
        _auth = auth ?? AuthService();

  final WorkspaceStore _store;
  final AuthService _auth;

  /// Whether the initial load is still running.
  bool loading = true;
  /// The workspace.
  Workspace workspace = const Workspace();
  /// The settings.
  AppSettings settings = const AppSettings();
  /// The live merge review, if one is active.
  MergeReviewState? review;

  /// Changes the last completed merge deliberately left behind, for the
  /// merged screen. Set during [executeMerge] before the review clears.
  List<Change> lastMergeLeftBehind = const [];
  /// The message from the last sync attempt.
  String? lastSyncMessage;

  /// The auth service.
  AuthService get auth => _auth;
  /// Whether a user is signed in.
  bool get signedIn => _auth.signedIn;
  /// Whether the session is a guest session.
  bool get isGuest => _auth.isGuest;
  /// Whether there is a session (signed in or guest).
  bool get hasSession => _auth.mode != SessionMode.none;
  /// Whether the user can edit (signed in, not a guest).
  bool get canEdit => _auth.signedIn;
  /// The signed-in user name, or empty.
  String get userName => _auth.displayName;
  /// The signed-in user email, or empty.
  String get userEmail => _auth.displayEmail;

  /// The open project.
  Project? get openProject => workspace.openProject;

  /// Returns the project with the given id, or null if there is none.
  Project? projectById(String id) => workspace.projectById(id);

  /// Loads persisted state (workspace, settings, auth). Called once at
  /// startup; [loading] flips false when done.
  Future<void> init() async {
    await _auth.load();
    workspace = await _store.loadWorkspace();
    settings = await _store.loadSettings();
    loading = false;
    notifyListeners();
  }

  Future<void> _saveWorkspace() async {
    await _store.saveWorkspace(workspace);
  }

  Future<void> _saveSettings() async {
    await _store.saveSettings(settings);
  }

  void _replaceProject(Project updated) {
    workspace = workspace.copyWith(
      projects: [
        for (final p in workspace.projects)
          if (p.id == updated.id) updated else p,
      ],
    );
  }

  void _replaceBranch(Project project, Branch updated) {
    _replaceProject(project.copyWith(
      branches: [
        for (final b in project.branches)
          if (b.id == updated.id) updated else b,
      ],
    ));
  }

  void _addActivity(ActivityEvent event) {
    workspace = workspace.copyWith(
      activity: [event, ...workspace.activity],
    );
  }

  // ------------------------------------------------------------ projects

  /// Opens a project by id (and persists the choice). Named
  /// [openProjectById] to avoid clashing with the [openProject] getter.
  Future<void> openProjectById(String projectId) async {
    workspace = workspace.copyWith(openProjectId: projectId);
    await _saveWorkspace();
    notifyListeners();
  }

  /// Creates a project owned by the signed-in user, with a main branch
  /// and a first snapshot.
  Future<Project> createProject({
    required String name,
    required String kind,
    int sceneCount = 6,
  }) async {
    _requireEdit();
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Project name must not be empty.');
    }
    final id = 'proj-${DateTime.now().millisecondsSinceEpoch}';
    final scenes = [
      for (var i = 1; i <= sceneCount; i++)
        Scene(number: i, title: 'Scene $i'),
    ];
    final main = Branch(
      id: 'main',
      name: 'main',
      tagline: 'The locked cut',
      color: 0xFFB03220,
      prefix: 's',
      runtimeSeconds: 0,
      snapshots: [
        Snapshot(
          id: 's1',
          message: 'First assembly, $sceneCount scenes in order',
          author: userName,
          createdAt: DateTime.now(),
          branchId: 'main',
          changes: [
            Change(
              id: 's1-0',
              title: 'Assembly',
              detail: '$sceneCount scenes in order, first pass',
              meta: 'Assembly',
              kind: 'edit',
            ),
          ],
        ),
      ],
    );
    final project = Project(
      id: id,
      name: trimmed,
      kind: kind,
      subtitle: '$sceneCount scenes',
      scenes: scenes,
      branches: [main],
    );
    workspace = workspace.copyWith(
      projects: [...workspace.projects, project],
      openProjectId: id,
    );
    _addActivity(ActivityEvent(
      id: 'ev-${DateTime.now().millisecondsSinceEpoch}',
      kind: 'project',
      text: '$userName started $trimmed',
      ref: 's1 · Today',
      at: DateTime.now(),
    ));
    await _saveWorkspace();
    notifyListeners();
    return project;
  }

  /// Forks a demo project into the signed-in user's account: same
  /// content, new ids, owned by the user.
  Future<Project> forkProjectToAccount(Project project) async {
    _requireEdit();
    if (!project.isDemo) {
      throw ArgumentError('Only demo projects can be forked this way.');
    }
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final copy = Project(
      id: 'proj-$stamp',
      name: project.name,
      kind: project.kind,
      subtitle: project.subtitle,
      scenes: project.scenes,
      branches: project.branches,
      isDemo: false,
      mergeInReviewSource: project.mergeInReviewSource,
    );
    workspace = workspace.copyWith(
      projects: [...workspace.projects, copy],
      openProjectId: copy.id,
    );
    _addActivity(ActivityEvent(
      id: 'ev-fork-$stamp',
      kind: 'project',
      text: '$userName forked ${project.name} into their account',
      ref: 'fork · Today',
      at: DateTime.now(),
    ));
    await _saveWorkspace();
    notifyListeners();
    return copy;
  }

  /// Archives a project (kept, read-only). Archived projects stay listed
  /// but cannot be edited until unarchived.
  Future<void> setProjectArchived(Project project, bool archived) async {
    _requireEdit();
    _replaceProject(project.copyWith(archived: archived));
    await _saveWorkspace();
    notifyListeners();
  }

  // ------------------------------------------------------------ branches

  /// Creates a branch on the open project, forked from [forkFromId].
  Future<Branch> createBranch({
    required String name,
    required String forkFromId,
  }) async {
    _requireEdit();
    final Project project =
        openProject ?? (throw StateError('No project is open.'));
    final branch = BranchEngine.createBranch(
      project: project,
      name: name,
      forkFromSnapshotId: forkFromId,
    );
    _replaceProject(project.copyWith(
      branches: [...project.branches, branch],
    ));
    _addActivity(ActivityEvent(
      id: 'ev-branch-${DateTime.now().millisecondsSinceEpoch}',
      kind: 'branch',
      text: '$userName forked ${branch.name} from $forkFromId',
      ref: '${branch.prefix}1 · Today',
      at: DateTime.now(),
    ));
    await _saveWorkspace();
    notifyListeners();
    return branch;
  }

  /// Appends a snapshot to [branchId] on the open project.
  Future<Snapshot> takeSnapshot({
    required String branchId,
    required String message,
    String changeDetail = '',
    int? scene,
  }) async {
    _requireEdit();
    final project = openProject;
    final branch = project?.branchById(branchId);
    if (project == null || branch == null) {
      throw StateError('Branch not found.');
    }
    final changes = changeDetail.trim().isEmpty
        ? <Change>[]
        : [
            Change(
              id: 'chg-${DateTime.now().millisecondsSinceEpoch}-0',
              title: 'Edit',
              detail: changeDetail.trim(),
              meta: scene == null
                  ? 'On ${branch.name}'
                  : 'Scene $scene · on ${branch.name}',
              scenes: scene == null ? const [] : [scene],
            ),
          ];
    final updated = BranchEngine.takeSnapshot(
      branch: branch,
      message: message,
      author: userName,
      changes: changes,
    );
    _replaceBranch(project, updated);
    final created = updated.latest!;
    _addActivity(ActivityEvent(
      id: 'ev-snap-${DateTime.now().millisecondsSinceEpoch}',
      kind: 'snapshot',
      text: '$userName: ${message.trim()}',
      ref: BranchEngine.activityRef(created.id, created.createdAt),
      at: created.createdAt,
    ));
    await _saveWorkspace();
    notifyListeners();
    return created;
  }

  // ------------------------------------------------------------ diff/merge

  /// Starts (or restarts) a merge review between two branches of the open
  /// project. Selection defaults from the diff data.
  void startReview({required String sourceId, required String targetId}) {
    final project = openProject;
    final source = project?.branchById(sourceId);
    final target = project?.branchById(targetId);
    if (project == null || source == null || target == null) return;
    final diff = BranchEngine.diff(source: source, target: target);
    review = MergeReviewState(
      sourceId: sourceId,
      targetId: targetId,
      diff: diff,
      selectedIds: BranchEngine.defaultSelection(diff.changes),
    );
    notifyListeners();
  }

  /// Ticks or unticks a change in the live review.
  void toggleChange(String changeId, bool selected) {
    final current = review;
    if (current == null) return;
    if (selected) {
      current.selectedIds.add(changeId);
    } else {
      current.selectedIds.remove(changeId);
    }
    notifyListeners();
  }

  /// Records a conflict resolution: 'source' or 'target'.
  void resolveConflict(String changeId, String resolution) {
    final current = review;
    if (current == null) return;
    current.resolutions[changeId] = resolution;
    notifyListeners();
  }

  /// Lands the live review's merge on the target branch. Returns the new
  /// merge snapshot.
  Future<Snapshot> executeMerge() async {
    _requireEdit();
    final current = review;
    final project = openProject;
    final source = project?.branchById(current?.sourceId ?? '');
    final target = project?.branchById(current?.targetId ?? '');
    if (current == null || project == null || source == null ||
        target == null) {
      throw StateError('No merge review is active.');
    }
    final plan = current.plan;
    lastMergeLeftBehind = plan.leftBehind;
    final updated = BranchEngine.applyMerge(
      target: target,
      source: source,
      plan: plan,
      author: userName,
    );
    final created = updated.latest!;
    var updatedProject = project.copyWith(
      branches: [
        for (final b in project.branches)
          if (b.id == updated.id) updated else b,
      ],
    );
    if (updatedProject.mergeInReviewSource == source.id) {
      updatedProject =
          updatedProject.copyWith(clearMergeInReview: true);
    }
    _replaceProject(updatedProject);
    _addActivity(ActivityEvent(
      id: 'ev-merge-${DateTime.now().millisecondsSinceEpoch}',
      kind: 'merge',
      text: '$userName merged ${source.name} into ${target.name}',
      ref: BranchEngine.activityRef(created.id, created.createdAt),
      at: created.createdAt,
    ));
    review = null;
    await _saveWorkspace();
    notifyListeners();
    return created;
  }

  // ------------------------------------------------------------ restore

  /// Restores [snapshotId] on [branchId], appending a new snapshot.
  Future<Snapshot> restoreSnapshot({
    required String branchId,
    required String snapshotId,
  }) async {
    _requireEdit();
    final project = openProject;
    final branch = project?.branchById(branchId);
    if (project == null || branch == null) {
      throw StateError('Branch not found.');
    }
    Snapshot? target;
    for (final s in branch.snapshots) {
      if (s.id == snapshotId) target = s;
    }
    if (target == null) throw StateError('Snapshot not found.');
    final updated = BranchEngine.restoreSnapshot(
      branch: branch,
      snapshot: target,
      author: userName,
    );
    _replaceBranch(project, updated);
    final created = updated.latest!;
    _addActivity(ActivityEvent(
      id: 'ev-restore-${DateTime.now().millisecondsSinceEpoch}',
      kind: 'restore',
      text: '$userName restored ${target.restorePhrase}',
      ref: BranchEngine.activityRef(created.id, created.createdAt),
      at: created.createdAt,
    ));
    await _saveWorkspace();
    notifyListeners();
    return created;
  }

  // ------------------------------------------------------------ search

  /// Searches the open project for snapshots matching [query].
  List<SnapshotHit> searchSnapshots(String query) {
    final project = openProject;
    if (project == null) return const [];
    return BranchEngine.searchSnapshots(project, query);
  }

  // ------------------------------------------------------------ auth

  /// Continues as a guest (view-only, no account).
  Future<void> continueAsGuest() async {
    await _auth.continueAsGuest();
    notifyListeners();
  }

  /// Signs in with [email] and [password].
  Future<void> signIn({required String email, required String password}) async {
    await _auth.signIn(email: email, password: password);
    notifyListeners();
  }

  /// Creates an account and starts verification.
  Future<void> createAccount({
    required String name,
    required String email,
    required String password,
  }) async {
    await _auth.createAccount(
      name: name,
      email: email,
      password: password,
    );
    notifyListeners();
  }

  /// Verifies the pending signup with [code].
  Future<void> verify(String code) async {
    await _auth.verify(code);
    notifyListeners();
  }

  /// Generates a fresh verification code for the pending signup.
  Future<void> resendCode() async {
    await _auth.resendCode();
    notifyListeners();
  }

  /// Signs out and clears the session.
  Future<void> signOut() async {
    await _auth.signOut();
    review = null;
    notifyListeners();
  }

  /// Deletes the account and the user's own projects. Demo projects stay.
  Future<void> deleteAccount() async {
    await _auth.deleteCurrentAccount();
    workspace = workspace.copyWith(
      projects: workspace.projects.where((p) => p.isDemo).toList(),
      openProjectId: 'harbour-light',
    );
    review = null;
    await _saveWorkspace();
    notifyListeners();
  }

  // ------------------------------------------------------------ settings

  /// Updates the connection settings.
  Future<void> setConnection({
    bool? github,
    bool? frameio,
    bool? localFolder,
  }) async {
    settings = settings.copyWith(
      githubConnected: github,
      frameioConnected: frameio,
      localFolderConnected: localFolder,
    );
    await _saveSettings();
    notifyListeners();
  }

  /// Turns the review link on or off.
  Future<void> setReviewLink(bool on) async {
    settings = settings.copyWith(reviewLinkOn: on);
    await _saveSettings();
    notifyListeners();
  }

  /// Sets the sync server base URL.
  Future<void> setSyncBaseUrl(String url) async {
    settings = settings.copyWith(syncBaseUrl: url.trim());
    await _saveSettings();
    notifyListeners();
  }

  /// Pushes the workspace to the sync sketch server (when configured).
  /// Returns a human result message; never throws.
  Future<String> syncNow() async {
    final baseUrl = settings.syncBaseUrl;
    if (baseUrl.isEmpty) {
      lastSyncMessage = 'Sync is off — set a server URL in Settings first.';
      notifyListeners();
      return lastSyncMessage!;
    }
    try {
      final client = SyncClient(baseUrl: baseUrl);
      final healthy = await client.checkHealth();
      if (!healthy) {
        lastSyncMessage = 'Could not reach the sync server at $baseUrl.';
        notifyListeners();
        return lastSyncMessage!;
      }
      await client.pushWorkspace(workspace.toJson());
      lastSyncMessage = 'Synced ${workspace.snapshotCount} snapshots.';
      notifyListeners();
      return lastSyncMessage!;
    } on SyncException catch (e) {
      lastSyncMessage = 'Sync failed: ${e.message}';
      notifyListeners();
      return lastSyncMessage!;
    } catch (e) {
      lastSyncMessage = 'Sync failed: $e';
      notifyListeners();
      return lastSyncMessage!;
    }
  }

  /// Resets the workspace to the seeded demo content.
  Future<void> resetDemo() async {
    workspace = await _store.resetToDemo();
    review = null;
    notifyListeners();
  }

  /// The export document for the current workspace.
  String exportJson() => ExportService.workspaceJson(workspace);

  /// Copies the export JSON to the clipboard.
  Future<void> copyExport() async {
    await ExportService.copyToClipboard(workspace);
  }

  /// Saves the export file on native platforms; returns the path.
  Future<String> saveExport() => ExportService.saveToFile(workspace);

  void _requireEdit() {
    if (!canEdit) {
      throw StateError(
        'Guests cannot change anything — sign in to branch, merge and '
        'restore.',
      );
    }
  }

  /// Demo seed, for tests and the reset path.
  static Workspace seedWorkspace() => DemoData.seedWorkspace();
}
