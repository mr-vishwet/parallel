/// PARALLEL document model: projects, branches, snapshots, changes.
///
/// The catalog's rules, encoded here:
/// - Snapshots are immutable: branching copies a pointer, restoring and
///   merging only ever APPEND new snapshots. History only grows.
/// - Diffs reference stable object identities (change ids, scene numbers),
///   not array positions.
/// - A merge is a reviewable plan: only picked changes travel, conflicts
///   are explicit and the app never guesses.
///
/// All models round-trip through JSON (see [WorkspaceStore]); the schema
/// version lives in the store key, not in the document.
library;

/// One scene (film) or frame group (photo series) in a project.
class Scene {
  /// Creates a [Scene].
  const Scene({required this.number, required this.title});

  /// The number.
  final int number;
  /// The title.
  final String title;

  /// Converts this to JSON.
  Map<String, dynamic> toJson() => {'number': number, 'title': title};

  /// Creates a [Scene] from JSON.
  factory Scene.fromJson(Map<String, dynamic> json) => Scene(
        number: json['number'] as int,
        title: json['title'] as String,
      );
}

/// One human-language change inside a snapshot.
///
/// A change is the unit the diff shows and the merge moves. [scenes] lists
/// every scene the change touches (used by the timeline and by conflict
/// detection); [kind] groups changes by nature ('shot', 'order', 'grade',
/// 'runtime', 'voiceover', 'sound', 'edit', 'pacing', 'credits').
class Change {
  /// Creates a [Change].
  const Change({
    required this.id,
    required this.title,
    required this.detail,
    required this.meta,
    this.scenes = const [],
    this.kind = 'edit',
    this.runtimeDeltaSeconds = 0,
    this.conflict = false,
    this.conflictNote,
    this.selectedByDefault = true,
  });

  /// The id.
  final String id;
  /// The title.
  final String title;
  /// What changed, in human language.
  final String detail;
  /// The meta line shown under the detail.
  final String meta;
  /// The scenes this change touches.
  final List<int> scenes;
  /// The kind of change.
  final String kind;
  /// How the runtime moves when this change lands, in seconds.
  final int runtimeDeltaSeconds;

  /// True when this change conflicts with the merge target. Seeded from
  /// the demo canon (the opening shot: Dev reframed the boathouse on main
  /// after c1) or detected by [BranchEngine] when both sides changed the
  /// same scene in the same way after the fork.
  final bool conflict;
  /// Why this change conflicts, if it does.
  final String? conflictNote;

  /// Whether the merge review ticks this change by default. The demo's
  /// cinematic-vs-main diff leaves runtime and voiceover unticked, as the
  /// V7 screens show; user-created changes default to ticked.
  final bool selectedByDefault;

  /// Returns a copy of this with the given values replaced.
  Change copyWith({bool? conflict, String? conflictNote}) => Change(
        id: id,
        title: title,
        detail: detail,
        meta: meta,
        scenes: scenes,
        kind: kind,
        runtimeDeltaSeconds: runtimeDeltaSeconds,
        conflict: conflict ?? this.conflict,
        conflictNote: conflictNote ?? this.conflictNote,
        selectedByDefault: selectedByDefault,
      );

  /// Converts this to JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'detail': detail,
        'meta': meta,
        'scenes': scenes,
        'kind': kind,
        'runtimeDeltaSeconds': runtimeDeltaSeconds,
        'conflict': conflict,
        'conflictNote': conflictNote,
        'selectedByDefault': selectedByDefault,
      };

  /// Creates a [Change] from JSON.
  factory Change.fromJson(Map<String, dynamic> json) => Change(
        id: json['id'] as String,
        title: json['title'] as String,
        detail: json['detail'] as String,
        meta: json['meta'] as String,
        scenes: (json['scenes'] as List<dynamic>? ?? [])
            .map((e) => e as int)
            .toList(),
        kind: json['kind'] as String? ?? 'edit',
        runtimeDeltaSeconds: json['runtimeDeltaSeconds'] as int? ?? 0,
        conflict: json['conflict'] as bool? ?? false,
        conflictNote: json['conflictNote'] as String?,
        selectedByDefault: json['selectedByDefault'] as bool? ?? true,
      );
}

/// One snapshot: a message, an author, a time, and exactly what changed.
///
/// Immutable once created. [parentId] is the previous snapshot on the same
/// branch; [restores] names the snapshot a restore brings back; [mergeOf]
/// names the branch a merge snapshot merged from.
class Snapshot {
  /// Creates a [Snapshot].
  const Snapshot({
    required this.id,
    required this.message,
    required this.author,
    required this.createdAt,
    required this.branchId,
    this.changes = const [],
    this.parentId,
    this.restores,
    this.mergeOf,
    this.restoreLabel,
  });

  /// The id.
  final String id;
  /// The message.
  final String message;
  /// The author.
  final String author;
  /// When this snapshot was taken.
  final DateTime createdAt;
  /// The branch id.
  final String branchId;
  /// The changes.
  final List<Change> changes;
  /// The parent id.
  final String? parentId;
  /// The snapshot id this restore brings back.
  final String? restores;
  /// The branch id this merge merged from.
  final String? mergeOf;

  /// Human phrase used when this snapshot is restored, e.g.
  /// "the second voiceover pass" (m6). Defaults to a short form of the
  /// message when absent.
  final String? restoreLabel;

  /// Whether this snapshot is a merge.
  bool get isMerge => mergeOf != null;
  /// Whether this snapshot is a restore.
  bool get isRestore => restores != null;

  /// What a restore of this snapshot would bring back, in plain words.
  String get restorePhrase => restoreLabel ?? message.toLowerCase();

  /// Converts this to JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'message': message,
        'author': author,
        'createdAt': createdAt.toIso8601String(),
        'branchId': branchId,
        'changes': changes.map((c) => c.toJson()).toList(),
        'parentId': parentId,
        'restores': restores,
        'mergeOf': mergeOf,
        'restoreLabel': restoreLabel,
      };

  /// Creates a [Snapshot] from JSON.
  factory Snapshot.fromJson(Map<String, dynamic> json) => Snapshot(
        id: json['id'] as String,
        message: json['message'] as String,
        author: json['author'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        branchId: json['branchId'] as String,
        changes: (json['changes'] as List<dynamic>? ?? [])
            .map((e) => Change.fromJson(e as Map<String, dynamic>))
            .toList(),
        parentId: json['parentId'] as String?,
        restores: json['restores'] as String?,
        mergeOf: json['mergeOf'] as String?,
        restoreLabel: json['restoreLabel'] as String?,
      );
}

/// One timeline of a project. Snapshots are stored newest-first.
class Branch {
  /// Creates a [Branch].
  const Branch({
    required this.id,
    required this.name,
    required this.tagline,
    required this.color,
    required this.prefix,
    required this.runtimeSeconds,
    this.forkedFrom,
    this.snapshots = const [],
  });

  /// The id.
  final String id;
  /// The name.
  final String name;
  /// The tagline.
  final String tagline;

  /// ARGB glow colour for the branch (see [BranchPalette]).
  final int color;

  /// Snapshot id prefix, e.g. 'm' for main, 'c' for cinematic.
  final String prefix;

  /// Snapshot id this branch forked from (null for main).
  final String? forkedFrom;

  /// Runtime in seconds of the branch's latest cut.
  final int runtimeSeconds;

  /// Newest first. Never mutated in place — the engine returns new
  /// branches with appended snapshots.
  final List<Snapshot> snapshots;

  /// The newest snapshot, or null if there are none.
  Snapshot? get latest => snapshots.isEmpty ? null : snapshots.first;

  /// The number of snapshots.
  int get snapshotCount => snapshots.length;

  /// Returns a copy of this with the given values replaced.
  Branch copyWith({
    String? tagline,
    int? runtimeSeconds,
    List<Snapshot>? snapshots,
  }) =>
      Branch(
        id: id,
        name: name,
        tagline: tagline ?? this.tagline,
        color: color,
        prefix: prefix,
        forkedFrom: forkedFrom,
        runtimeSeconds: runtimeSeconds ?? this.runtimeSeconds,
        snapshots: snapshots ?? this.snapshots,
      );

  /// Converts this to JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'tagline': tagline,
        'color': color,
        'prefix': prefix,
        'forkedFrom': forkedFrom,
        'runtimeSeconds': runtimeSeconds,
        'snapshots': snapshots.map((s) => s.toJson()).toList(),
      };

  /// Creates a [Branch] from JSON.
  factory Branch.fromJson(Map<String, dynamic> json) => Branch(
        id: json['id'] as String,
        name: json['name'] as String,
        tagline: json['tagline'] as String,
        color: json['color'] as int,
        prefix: json['prefix'] as String,
        forkedFrom: json['forkedFrom'] as String?,
        runtimeSeconds: json['runtimeSeconds'] as int,
        snapshots: (json['snapshots'] as List<dynamic>? ?? [])
            .map((e) => Snapshot.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// A creative project: scenes plus the branches that explore them.
class Project {
  /// Creates a [Project].
  const Project({
    required this.id,
    required this.name,
    required this.kind,
    required this.subtitle,
    this.scenes = const [],
    this.branches = const [],
    this.isDemo = false,
    this.archived = false,
    this.mergeInReviewSource,
  });

  /// The id.
  final String id;
  /// The name.
  final String name;

  /// 'Short film', 'Brand film', 'Photo series', ...
  final String kind;

  /// One-line summary, e.g. '3:48 · 14 scenes'.
  final String subtitle;
  /// The scenes.
  final List<Scene> scenes;
  /// The branches.
  final List<Branch> branches;

  /// Demo projects belong to the demo, not to the user. Guests view them
  /// read-only; signed-in users fork them into their own account.
  final bool isDemo;
  /// Whether this project is archived.
  final bool archived;

  /// Branch id with a merge into main currently in review (null when none).
  final String? mergeInReviewSource;

  /// Returns the branch with the given id, or null if there is none.
  Branch? branchById(String id) {
    for (final b in branches) {
      if (b.id == id) return b;
    }
    return null;
  }

  /// The main branch.
  Branch get mainBranch => branchById('main') ?? branches.first;

  /// The number of snapshots across all branches.
  int get snapshotCount =>
      branches.fold(0, (sum, b) => sum + b.snapshotCount);

  /// Returns a copy of this with the given values replaced.
  Project copyWith({
    String? subtitle,
    List<Branch>? branches,
    bool? archived,
    String? mergeInReviewSource,
    bool clearMergeInReview = false,
  }) =>
      Project(
        id: id,
        name: name,
        kind: kind,
        subtitle: subtitle ?? this.subtitle,
        scenes: scenes,
        branches: branches ?? this.branches,
        isDemo: isDemo,
        archived: archived ?? this.archived,
        mergeInReviewSource: clearMergeInReview
            ? null
            : (mergeInReviewSource ?? this.mergeInReviewSource),
      );

  /// Converts this to JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'kind': kind,
        'subtitle': subtitle,
        'scenes': scenes.map((s) => s.toJson()).toList(),
        'branches': branches.map((b) => b.toJson()).toList(),
        'isDemo': isDemo,
        'archived': archived,
        'mergeInReviewSource': mergeInReviewSource,
      };

  /// Creates a [Project] from JSON.
  factory Project.fromJson(Map<String, dynamic> json) => Project(
        id: json['id'] as String,
        name: json['name'] as String,
        kind: json['kind'] as String,
        subtitle: json['subtitle'] as String,
        scenes: (json['scenes'] as List<dynamic>? ?? [])
            .map((e) => Scene.fromJson(e as Map<String, dynamic>))
            .toList(),
        branches: (json['branches'] as List<dynamic>? ?? [])
            .map((e) => Branch.fromJson(e as Map<String, dynamic>))
            .toList(),
        isDemo: json['isDemo'] as bool? ?? false,
        archived: json['archived'] as bool? ?? false,
        mergeInReviewSource: json['mergeInReviewSource'] as String?,
      );
}

/// One activity-feed entry: every branch, merge and restore, with the
/// person attached.
class ActivityEvent {
  /// Creates an [ActivityEvent].
  const ActivityEvent({
    required this.id,
    required this.kind,
    required this.text,
    required this.ref,
    required this.at,
  });

  /// The id.
  final String id;

  /// 'branch' | 'merge' | 'restore' | 'snapshot' | 'project'.
  final String kind;
  /// The feed text.
  final String text;

  /// Short ref, e.g. 'm11 · Today 10:04'.
  final String ref;
  /// When this happened.
  final DateTime at;

  /// Converts this to JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind,
        'text': text,
        'ref': ref,
        'at': at.toIso8601String(),
      };

  /// Creates an [ActivityEvent] from JSON.
  factory ActivityEvent.fromJson(Map<String, dynamic> json) => ActivityEvent(
        id: json['id'] as String,
        kind: json['kind'] as String,
        text: json['text'] as String,
        ref: json['ref'] as String,
        at: DateTime.parse(json['at'] as String),
      );
}

/// App-level settings: connections, review link, sync stub URL.
class AppSettings {
  /// Creates an [AppSettings].
  const AppSettings({
    this.githubConnected = false,
    this.frameioConnected = false,
    this.localFolderConnected = false,
    this.reviewLinkOn = false,
    this.syncBaseUrl = '',
  });

  /// Whether GitHub is connected.
  final bool githubConnected;
  /// Whether Frame.io is connected.
  final bool frameioConnected;
  /// Whether a local folder is connected.
  final bool localFolderConnected;
  /// Whether the review link is on.
  final bool reviewLinkOn;

  /// Base URL of the sync sketch server (empty = sync off). See server/.
  final String syncBaseUrl;

  /// Returns a copy of this with the given values replaced.
  AppSettings copyWith({
    bool? githubConnected,
    bool? frameioConnected,
    bool? localFolderConnected,
    bool? reviewLinkOn,
    String? syncBaseUrl,
  }) =>
      AppSettings(
        githubConnected: githubConnected ?? this.githubConnected,
        frameioConnected: frameioConnected ?? this.frameioConnected,
        localFolderConnected:
            localFolderConnected ?? this.localFolderConnected,
        reviewLinkOn: reviewLinkOn ?? this.reviewLinkOn,
        syncBaseUrl: syncBaseUrl ?? this.syncBaseUrl,
      );

  /// Converts this to JSON.
  Map<String, dynamic> toJson() => {
        'githubConnected': githubConnected,
        'frameioConnected': frameioConnected,
        'localFolderConnected': localFolderConnected,
        'reviewLinkOn': reviewLinkOn,
        'syncBaseUrl': syncBaseUrl,
      };

  /// Creates an [AppSettings] from JSON.
  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        githubConnected: json['githubConnected'] as bool? ?? false,
        frameioConnected: json['frameioConnected'] as bool? ?? false,
        localFolderConnected: json['localFolderConnected'] as bool? ?? false,
        reviewLinkOn: json['reviewLinkOn'] as bool? ?? false,
        syncBaseUrl: json['syncBaseUrl'] as String? ?? '',
      );
}

/// The whole local workspace: projects, activity, and which project is open.
class Workspace {
  /// Creates a [Workspace].
  const Workspace({
    this.projects = const [],
    this.activity = const [],
    this.openProjectId = 'harbour-light',
  });

  /// The projects.
  final List<Project> projects;

  /// Newest first.
  final List<ActivityEvent> activity;
  /// The open project id.
  final String openProjectId;

  /// The open project.
  Project? get openProject {
    for (final p in projects) {
      if (p.id == openProjectId) return p;
    }
    return projects.isEmpty ? null : projects.first;
  }

  /// Returns the project with the given id, or null if there is none.
  Project? projectById(String id) {
    for (final p in projects) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// The number of branches across all projects.
  int get branchCount => projects.fold(0, (sum, p) => sum + p.branches.length);

  /// The number of snapshots across all projects.
  int get snapshotCount =>
      projects.fold(0, (sum, p) => sum + p.snapshotCount);

  /// The number of merges in the activity feed.
  int get mergeCount =>
      activity.where((e) => e.kind == 'merge').length;

  /// The number of projects with a merge in review.
  int get mergesInReview =>
      projects.where((p) => p.mergeInReviewSource != null).length;

  /// Returns a copy of this with the given values replaced.
  Workspace copyWith({
    List<Project>? projects,
    List<ActivityEvent>? activity,
    String? openProjectId,
  }) =>
      Workspace(
        projects: projects ?? this.projects,
        activity: activity ?? this.activity,
        openProjectId: openProjectId ?? this.openProjectId,
      );

  /// Converts this to JSON.
  Map<String, dynamic> toJson() => {
        'projects': projects.map((p) => p.toJson()).toList(),
        'activity': activity.map((e) => e.toJson()).toList(),
        'openProjectId': openProjectId,
      };

  /// Creates a [Workspace] from JSON.
  factory Workspace.fromJson(Map<String, dynamic> json) => Workspace(
        projects: (json['projects'] as List<dynamic>? ?? [])
            .map((e) => Project.fromJson(e as Map<String, dynamic>))
            .toList(),
        activity: (json['activity'] as List<dynamic>? ?? [])
            .map((e) => ActivityEvent.fromJson(e as Map<String, dynamic>))
            .toList(),
        openProjectId: json['openProjectId'] as String? ?? 'harbour-light',
      );
}
