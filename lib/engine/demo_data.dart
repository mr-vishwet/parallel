import '../core/constants.dart';
import 'models.dart';

/// Seeded demo workspace — the V7 canon, as data.
///
/// Harbour Light: a 3:48 short film, 14 scenes, 4 branches, 21 snapshots.
/// Launch Teaser: a 0:30 brand film, 6 scenes, 2 branches, 8 snapshots.
/// Field Notes: a photo series, 24 frames, 1 branch, 5 snapshots.
/// Totals: 3 projects, 7 branches, 34 snapshots, 2 merges, 1 in review.
///
/// This is SEEDED DEMO CONTENT, labelled as demo wherever it shows. The
/// timestamps are relative to first launch so "Today 09:41" stays true;
/// the clock times match the V7 screens.
class DemoData {
  DemoData._();

  /// A time [daysAgo] days before now at [hour]:[minute], clamped to now
  /// so a seed never lands in the future.
  static DateTime demoTime({
    required int daysAgo,
    required int hour,
    required int minute,
  }) {
    final now = DateTime.now();
    final base = DateTime(now.year, now.month, now.day, hour, minute)
        .subtract(Duration(days: daysAgo));
    return base.isAfter(now) ? now : base;
  }

  static const List<String> harbourScenes = [
    'Harbour dawn',
    'The boathouse',
    "Mara's hands",
    'Voiceover: the letter',
    'The storm tape',
    'Night ferry',
    'The argument',
    'Quiet kitchen',
    'The map',
    'Low tide',
    'The phone call',
    'Rooftop',
    'Last light',
    'Credits over water',
  ];

  static Change _chg(
    String id,
    String title,
    String detail,
    String meta, {
    List<int> scenes = const [],
    String kind = 'edit',
    int runtimeDeltaSeconds = 0,
    bool conflict = false,
    String? conflictNote,
    bool selectedByDefault = true,
  }) =>
      Change(
        id: id,
        title: title,
        detail: detail,
        meta: meta,
        scenes: scenes,
        kind: kind,
        runtimeDeltaSeconds: runtimeDeltaSeconds,
        conflict: conflict,
        conflictNote: conflictNote,
        selectedByDefault: selectedByDefault,
      );

  static Snapshot _snap(
    String id,
    String message,
    String author,
    DateTime at,
    String branchId,
    List<Change> changes, {
    String? parentId,
    String? restoreLabel,
  }) =>
      Snapshot(
        id: id,
        message: message,
        author: author,
        createdAt: at,
        branchId: branchId,
        changes: changes,
        parentId: parentId,
        restoreLabel: restoreLabel,
      );

  /// The full seeded workspace.
  static Workspace seedWorkspace() {
    final harbour = _harbourLight();
    final teaser = _launchTeaser();
    final notes = _fieldNotes();
    return Workspace(
      projects: [harbour, teaser, notes],
      activity: seedActivity(),
      openProjectId: harbour.id,
    );
  }

  static Project _harbourLight() {
    const mara = DemoFigures.authorMara;
    const dev = DemoFigures.authorDev;
    final scenes = [
      for (var i = 0; i < harbourScenes.length; i++)
        Scene(number: i + 1, title: harbourScenes[i]),
    ];

    // main: 9 snapshots, newest first. 3:48 = 228s.
    final m1 = _snap('m1', 'First assembly, all 14 scenes in order', mara,
        demoTime(daysAgo: 4, hour: 14, minute: 12), 'main', [
      _chg('m1-0', 'Assembly', 'All 14 scenes in order, first pass',
          'Scenes 1–14 · assembly',
          scenes: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14],
          kind: 'edit'),
    ]);
    final m2 = _snap('m2', 'Added the letter voiceover to scene 4', mara,
        demoTime(daysAgo: 3, hour: 9, minute: 58), 'main', [
      _chg('m2-0', 'Voiceover', 'The letter is read over the hands',
          'Scene 4 · 0:18 added',
          scenes: [4], kind: 'voiceover'),
    ], parentId: 'm1');
    final m3 = _snap('m3', 'Replaced the harbour dawn opening', mara,
        demoTime(daysAgo: 3, hour: 16, minute: 31), 'main', [
      _chg('m3-0', 'Opening shot', 'The film now opens in the boathouse',
          'Shot replaced · scene 1',
          scenes: [1], kind: 'shot'),
    ], parentId: 'm2');
    final m4 = _snap('m4', 'Shortened the ferry crossing by half', dev,
        demoTime(daysAgo: 2, hour: 10, minute: 3), 'main', [
      _chg('m4-0', 'Pacing', 'The ferry crossing runs half as long',
          'Scene 6 · timing',
          scenes: [6], kind: 'pacing', runtimeDeltaSeconds: -8),
    ], parentId: 'm3');
    final m5 = _snap('m5', 'Swapped the kitchen and map scenes', mara,
        demoTime(daysAgo: 2, hour: 17, minute: 44), 'main', [
      _chg('m5-0', 'Scene order', 'Quiet kitchen now follows the map',
          'Scenes 8 and 9 swapped',
          scenes: [8, 9], kind: 'order'),
    ], parentId: 'm4');
    final m6 = _snap('m6', 'Cut the second voiceover pass', mara,
        demoTime(daysAgo: 1, hour: 9, minute: 15), 'main', [
      _chg('m6-0', 'Voiceover', 'The second reading of the letter is out',
          'Scene 4 · 0:18 removed',
          scenes: [4], kind: 'voiceover', runtimeDeltaSeconds: -18),
    ], parentId: 'm5', restoreLabel: 'the second voiceover pass');
    final m7 = _snap('m7', 'Put the storm tape back in scene 5', dev,
        demoTime(daysAgo: 1, hour: 11, minute: 20), 'main', [
      _chg('m7-0', 'Sound', 'The storm tape returns under the argument',
          'Scene 5 · sound',
          scenes: [5], kind: 'sound'),
    ], parentId: 'm6');
    final m8 = _snap('m8', 'Trimmed the phone call to one line', mara,
        demoTime(daysAgo: 1, hour: 18, minute: 2), 'main', [
      _chg('m8-0', 'Dialogue', 'The phone call is one line now',
          'Scene 11 · 0:09 removed',
          scenes: [11], kind: 'edit', runtimeDeltaSeconds: -9),
    ], parentId: 'm7');
    final m9 = _snap('m9', 'Locked the ending after the rooftop take', mara,
        demoTime(daysAgo: 0, hour: 9, minute: 41), 'main', [
      _chg('m9-0', 'Ending', 'Ending held 6 seconds longer',
          'Scene 13 · Last light',
          scenes: [13], kind: 'edit', runtimeDeltaSeconds: 6),
      _chg('m9-1', 'Shot replaced',
          'Rooftop take replaces the balcony take', 'Scene 12 · shot replaced',
          scenes: [12], kind: 'shot'),
      _chg('m9-2', 'Timing', 'Credits start 2 seconds later',
          'Scene 14 · timing',
          scenes: [14], kind: 'edit', runtimeDeltaSeconds: 2),
    ], parentId: 'm8');
    final main = Branch(
      id: 'main',
      name: 'main',
      tagline: 'The locked cut',
      color: BranchPalette.byBranchId['main']!,
      prefix: 'm',
      runtimeSeconds: 228,
      snapshots: [m9, m8, m7, m6, m5, m4, m3, m2, m1],
    );

    // cinematic: forked from m3, 4 snapshots, 4:02 = 242s (+14s).
    // Its 5 changes are the visual diff vs main.
    final c1 = _snap('c1', 'Opened on the harbour instead of the boathouse',
        mara, demoTime(daysAgo: 2, hour: 15, minute: 22), 'cinematic', [
      _chg('c1-0', 'Opening shot',
          'Opens on the harbour instead of the boathouse',
          'Shot replaced · scene 1',
          scenes: [1],
          kind: 'shot',
          runtimeDeltaSeconds: 2,
          conflict: true,
          conflictNote:
              'Dev reframed the boathouse shot on main after c1. Pick one '
              'in the merge — PARALLEL never guesses.'),
    ]);
    final c2 = _snap('c2', 'Moved the argument before the night ferry', mara,
        demoTime(daysAgo: 1, hour: 13, minute: 5), 'cinematic', [
      _chg('c2-0', 'Scene order',
          'The argument now comes before the night ferry',
          'Scenes 6 and 7 swapped',
          scenes: [6, 7], kind: 'order'),
    ], parentId: 'c1');
    final c3 = _snap('c3', 'Warmed the grade across the night scenes', dev,
        demoTime(daysAgo: 1, hour: 19, minute: 36), 'cinematic', [
      _chg('c3-0', 'Grade',
          'Shadows lifted, midtones warmed across the night scenes',
          'Grade · scenes 6, 12, 13',
          scenes: [6, 12, 13], kind: 'grade'),
    ], parentId: 'c2');
    final c4 = _snap('c4', 'Held the last light shot for 6 more seconds',
        mara, demoTime(daysAgo: 0, hour: 8, minute: 20), 'cinematic', [
      _chg('c4-0', 'Runtime',
          '14 seconds longer, mostly the held last-light shot',
          '3:48 → 4:02',
          scenes: [13],
          kind: 'runtime',
          runtimeDeltaSeconds: 12,
          selectedByDefault: false),
      _chg('c4-1', 'Voiceover',
          'The letter voiceover kept, trimmed by 6 seconds',
          'Scene 4 · 0:18 → 0:12',
          scenes: [4], kind: 'voiceover', selectedByDefault: false),
    ], parentId: 'c3');
    final cinematic = Branch(
      id: 'cinematic',
      name: 'cinematic',
      tagline: 'Long takes, warm grade. Opens on the harbour.',
      color: BranchPalette.byBranchId['cinematic']!,
      prefix: 'c',
      forkedFrom: 'm3',
      runtimeSeconds: 242,
      snapshots: [c4, c3, c2, c1],
    );

    // minimal: forked from m5, 3 snapshots, 3:31 = 211s (−17s).
    final n1 = _snap('n1', 'Cut every scene to its first breath', mara,
        demoTime(daysAgo: 3, hour: 11, minute: 9), 'minimal', [
      _chg('n1-0', 'Pacing', 'Every scene cut to its first breath',
          'All scenes · pacing',
          scenes: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14],
          kind: 'pacing',
          runtimeDeltaSeconds: -10),
    ]);
    final n2 = _snap('n2', 'Removed the voiceover from scene 4', mara,
        demoTime(daysAgo: 2, hour: 12, minute: 40), 'minimal', [
      _chg('n2-0', 'Voiceover', 'Scene 4 plays without the letter',
          'Scene 4 · voiceover removed',
          scenes: [4], kind: 'voiceover', runtimeDeltaSeconds: -7),
    ], parentId: 'n1');
    final n3 = _snap('n3', 'Took the score out of the middle third', mara,
        demoTime(daysAgo: 1, hour: 16, minute: 48), 'minimal', [
      _chg('n3-0', 'Score', 'No score in the middle third',
          'Scenes 5–9 · score removed',
          scenes: [5, 6, 7, 8, 9], kind: 'sound'),
    ], parentId: 'n2');
    final minimal = Branch(
      id: 'minimal',
      name: 'minimal',
      tagline: 'No voiceover, no score in the middle third.',
      color: BranchPalette.byBranchId['minimal']!,
      prefix: 'n',
      forkedFrom: 'm5',
      runtimeSeconds: 211,
      snapshots: [n3, n2, n1],
    );

    // experimental: forked from m7, 5 snapshots, 3:56 = 236s (+8s).
    final e1 = _snap('e1', 'Forked from m7 to test a silent ending', mara,
        demoTime(daysAgo: 3, hour: 15, minute: 47), 'experimental', [
      _chg('e1-0', 'Ending', 'Testing a silent ending from here',
          'Scene 14 · ending',
          scenes: [14], kind: 'edit'),
    ]);
    final e2 = _snap('e2', 'Muted the storm tape entirely', dev,
        demoTime(daysAgo: 2, hour: 9, minute: 31), 'experimental', [
      _chg('e2-0', 'Sound', 'The storm tape is muted end to end',
          'Scene 5 · sound',
          scenes: [5], kind: 'sound'),
    ], parentId: 'e1');
    final e3 = _snap('e3', 'Played scenes 9 to 12 in reverse order', mara,
        demoTime(daysAgo: 1, hour: 14, minute: 27), 'experimental', [
      _chg('e3-0', 'Scene order', 'Scenes 9 to 12 run in reverse',
          'Scenes 9–12 · order',
          scenes: [9, 10, 11, 12], kind: 'order'),
    ], parentId: 'e2');
    final e4 = _snap('e4', 'Ran the credits over water, no titles', dev,
        demoTime(daysAgo: 1, hour: 20, minute: 11), 'experimental', [
      _chg('e4-0', 'Credits', 'Credits over water, no title cards',
          'Scene 14 · credits',
          scenes: [14], kind: 'credits', runtimeDeltaSeconds: 8),
    ], parentId: 'e3');
    final e5 = _snap('e5', 'Ended on the phone call, no music', mara,
        demoTime(daysAgo: 0, hour: 7, minute: 55), 'experimental', [
      _chg('e5-0', 'Ending', 'The film ends on the phone call, silent',
          'Scene 11 · ending',
          scenes: [11], kind: 'edit'),
    ], parentId: 'e4');
    final experimental = Branch(
      id: 'experimental',
      name: 'experimental',
      tagline: 'Scenes reordered, ending without music.',
      color: BranchPalette.byBranchId['experimental']!,
      prefix: 'e',
      forkedFrom: 'm7',
      runtimeSeconds: 236,
      snapshots: [e5, e4, e3, e2, e1],
    );

    return Project(
      id: 'harbour-light',
      name: 'Harbour Light',
      kind: 'Short film',
      subtitle: '3:48 · 14 scenes',
      scenes: scenes,
      branches: [main, cinematic, minimal, experimental],
      isDemo: true,
      mergeInReviewSource: 'cinematic',
    );
  }

  static Project _launchTeaser() {
    const mara = DemoFigures.authorMara;
    final scenes = [
      const Scene(number: 1, title: 'Cold open'),
      const Scene(number: 2, title: 'The product'),
      const Scene(number: 3, title: 'Three beats'),
      const Scene(number: 4, title: 'The turn'),
      const Scene(number: 5, title: 'Logo sting'),
      const Scene(number: 6, title: 'Release date'),
    ];
    final t1 = _snap('t1', 'First assembly, six scenes in order', mara,
        demoTime(daysAgo: 6, hour: 10, minute: 5), 'main', [
      _chg('t1-0', 'Assembly', 'Six scenes in order, first pass',
          'Scenes 1–6 · assembly',
          scenes: [1, 2, 3, 4, 5, 6], kind: 'edit'),
    ]);
    final t2 = _snap('t2', 'Cut the cold open to two seconds', mara,
        demoTime(daysAgo: 5, hour: 16, minute: 40), 'main', [
      _chg('t2-0', 'Pacing', 'Cold open runs two seconds now',
          'Scene 1 · timing',
          scenes: [1], kind: 'pacing', runtimeDeltaSeconds: -3),
    ], parentId: 't1');
    final t3 = _snap('t3', 'Swapped beats two and three', mara,
        demoTime(daysAgo: 4, hour: 11, minute: 12), 'main', [
      _chg('t3-0', 'Scene order', 'Beats two and three swap places',
          'Scene 3 · order',
          scenes: [3], kind: 'order'),
    ], parentId: 't2');
    final t4 = _snap('t4', 'Logo sting lands on the beat', mara,
        demoTime(daysAgo: 3, hour: 9, minute: 30), 'main', [
      _chg('t4-0', 'Timing', 'The sting lands on the downbeat',
          'Scene 5 · timing',
          scenes: [5], kind: 'edit'),
    ], parentId: 't3');
    final t5 = _snap('t5', 'Locked the 0:30 cut', mara,
        demoTime(daysAgo: 2, hour: 14, minute: 2), 'main', [
      _chg('t5-0', 'Lock', 'The thirty-second cut is locked',
          'All scenes · locked',
          scenes: [1, 2, 3, 4, 5, 6], kind: 'edit'),
    ], parentId: 't4');
    final main = Branch(
      id: 'main',
      name: 'main',
      tagline: 'The locked cut',
      color: BranchPalette.byBranchId['main']!,
      prefix: 't',
      runtimeSeconds: 30,
      snapshots: [t5, t4, t3, t2, t1],
    );
    final a1 = _snap('a1', 'Tried the product first, no cold open', mara,
        demoTime(daysAgo: 3, hour: 18, minute: 20), 'alt-open', [
      _chg('a1-0', 'Opening shot', 'The product opens the teaser',
          'Shot replaced · scene 1',
          scenes: [1], kind: 'shot', runtimeDeltaSeconds: 2),
    ]);
    final a2 = _snap('a2', 'Held the turn for one more beat', mara,
        demoTime(daysAgo: 2, hour: 10, minute: 44), 'alt-open', [
      _chg('a2-0', 'Pacing', 'The turn holds a beat longer',
          'Scene 4 · timing',
          scenes: [4], kind: 'pacing', runtimeDeltaSeconds: 1),
    ], parentId: 'a1');
    final a3 = _snap('a3', 'Release date card, one second longer', mara,
        demoTime(daysAgo: 1, hour: 12, minute: 8), 'alt-open', [
      _chg('a3-0', 'Timing', 'The date card holds a second longer',
          'Scene 6 · timing',
          scenes: [6], kind: 'edit', runtimeDeltaSeconds: 1),
    ], parentId: 'a2');
    final alt = Branch(
      id: 'alt-open',
      name: 'alt-open',
      tagline: 'Product first, no cold open.',
      color: BranchPalette.byBranchId['cinematic']!,
      prefix: 'a',
      forkedFrom: 't3',
      runtimeSeconds: 34,
      snapshots: [a3, a2, a1],
    );
    return Project(
      id: 'launch-teaser',
      name: 'Launch Teaser',
      kind: 'Brand film',
      subtitle: '0:30 · 6 scenes',
      scenes: scenes,
      branches: [main, alt],
      isDemo: true,
    );
  }

  static Project _fieldNotes() {
    const mara = DemoFigures.authorMara;
    final scenes = [
      for (var i = 1; i <= 24; i++)
        Scene(number: i, title: 'Frame ${i.toString().padLeft(2, '0')}'),
    ];
    final f1 = _snap('f1', 'First pass, 24 frames in order', mara,
        demoTime(daysAgo: 8, hour: 15, minute: 20), 'main', [
      _chg('f1-0', 'Assembly', '24 frames in shooting order',
          'Frames 01–24 · assembly',
          scenes: [1, 2, 3, 4, 5, 6, 7, 8], kind: 'edit'),
    ]);
    final f2 = _snap('f2', 'Moved the harbour frames to the front', mara,
        demoTime(daysAgo: 7, hour: 10, minute: 2), 'main', [
      _chg('f2-0', 'Order', 'Harbour frames open the series',
          'Frames 03–06 · order',
          scenes: [3, 4, 5, 6], kind: 'order'),
    ], parentId: 'f1');
    final f3 = _snap('f3', 'Warmed the dusk frames', mara,
        demoTime(daysAgo: 6, hour: 19, minute: 45), 'main', [
      _chg('f3-0', 'Grade', 'Dusk frames warmed half a stop',
          'Frames 14–18 · grade',
          scenes: [14, 15, 16, 17, 18], kind: 'grade'),
    ], parentId: 'f2');
    final f4 = _snap('f4', 'Pulled two soft frames', mara,
        demoTime(daysAgo: 5, hour: 8, minute: 30), 'main', [
      _chg('f4-0', 'Curation', 'Two soft frames pulled from the series',
          'Frames 09, 21 · curation',
          scenes: [9, 21], kind: 'edit'),
    ], parentId: 'f3');
    final f5 = _snap('f5', 'Locked the sequence', mara,
        demoTime(daysAgo: 4, hour: 17, minute: 11), 'main', [
      _chg('f5-0', 'Lock', 'The sequence is locked',
          'All frames · locked',
          scenes: [1, 2, 3, 4, 5, 6], kind: 'edit'),
    ], parentId: 'f4');
    final main = Branch(
      id: 'main',
      name: 'main',
      tagline: 'The locked sequence',
      color: BranchPalette.byBranchId['main']!,
      prefix: 'f',
      runtimeSeconds: 0,
      snapshots: [f5, f4, f3, f2, f1],
    );
    return Project(
      id: 'field-notes',
      name: 'Field Notes',
      kind: 'Photo series',
      subtitle: '24 frames',
      scenes: scenes,
      branches: [main],
      isDemo: true,
    );
  }

  /// Seeded activity: the V7 feed (m19), newest first.
  ///
  /// Note: the deck's feed also shows the m11 merge and the m10 restore as
  /// done, but in the app's live state main is still at m9 and that merge
  /// is in review — the user creates m10 and m11 by using the app. The
  /// seed therefore stops at m9; merge/restore events are appended live.
  static List<ActivityEvent> seedActivity() {
    final now = DateTime.now();
    return [
      ActivityEvent(
        id: 'ev-m9',
        kind: 'snapshot',
        text: 'Mara locked the ending after the rooftop take',
        ref: 'm9 · Today 09:41',
        at: demoTime(daysAgo: 0, hour: 9, minute: 41),
      ),
      ActivityEvent(
        id: 'ev-fork-exp',
        kind: 'branch',
        text: 'Mara forked experimental from m7',
        ref: 'e1 · 3 days ago',
        at: now.subtract(const Duration(days: 3)),
      ),
      ActivityEvent(
        id: 'ev-m7',
        kind: 'snapshot',
        text: 'Dev put the storm tape back in scene 5',
        ref: 'm7 · Yesterday 11:20',
        at: demoTime(daysAgo: 1, hour: 11, minute: 20),
      ),
      ActivityEvent(
        id: 'ev-fork-min',
        kind: 'branch',
        text: 'Mara forked minimal from m5',
        ref: 'n1 · 3 days ago',
        at: now.subtract(const Duration(days: 3, hours: 2)),
      ),
    ];
  }
}
