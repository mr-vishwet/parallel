import 'package:flutter/material.dart';

import 'core/routes.dart';
import 'core/theme.dart';
import 'screens/account_screen.dart';
import 'screens/activity_screen.dart';
import 'screens/branch_detail_screen.dart';
import 'screens/branch_map_screen.dart';
import 'screens/change_detail_screen.dart';
import 'screens/compare_screen.dart';
import 'screens/conflict_screen.dart';
import 'screens/connected_screen.dart';
import 'screens/create_account_screen.dart';
import 'screens/data_controls_screen.dart';
import 'screens/diff_screen.dart';
import 'screens/guest_screen.dart';
import 'screens/merge_screen.dart';
import 'screens/merged_screen.dart';
import 'screens/migrate_screen.dart';
import 'screens/new_branch_screen.dart';
import 'screens/projects_screen.dart';
import 'screens/restore_screen.dart';
import 'screens/restored_screen.dart';
import 'screens/search_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/sign_in_screen.dart';
import 'screens/snapshot_detail_screen.dart';
import 'screens/snapshots_screen.dart';
import 'screens/timeline_screen.dart';
import 'screens/upgrade_screen.dart';
import 'screens/verify_screen.dart';
import 'screens/welcome_screen.dart';
import 'state/app_controller.dart';
import 'widgets/app_logo.dart';

/// PARALLEL app shell.
///
/// One [AppController] owns the workspace, auth, settings and the live
/// merge review; [AppScope] exposes it to every screen. The first screen
/// is Projects when a session exists (signed in or guest) and Welcome
/// otherwise (see [_StartupGate]). Phase 1 uses the single V7 light
/// theme; the dual-theme system is phase 2.
class ParallelApp extends StatefulWidget {
  const ParallelApp({super.key});

  @override
  State<ParallelApp> createState() => _ParallelAppState();
}

class _ParallelAppState extends State<ParallelApp> {
  late final AppController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AppController()..init();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ONE MaterialApp for the app's whole life. Swapping between two
    // MaterialApps (a splash one with `home`, a main one without) crashes
    // in release: the Navigator keeps the "/" route, whose builder is the
    // framework closure `(context) => widget.home!` — after the swap
    // `home` is null and that closure throws "Null check operator used on
    // a null value" when the route rebuilds (deployed main.dart.js
    // aDt.$1, line 76386). The loading gate lives INSIDE `home` instead,
    // so `home` is never null. (The swap was doubly broken: `initialRoute`
    // is only read when the Navigator is created, so the swapped-in
    // MaterialApp's initialRoute was silently ignored and the app would
    // have stayed on the splash even without the crash.)
    return AppScope(
      controller: _controller,
      child: MaterialApp(
        title: 'PARALLEL',
        theme: AppTheme.light,
        home: const _StartupGate(),
        onGenerateRoute: _onGenerateRoute,
      ),
    );
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    Widget screen;
    switch (settings.name) {
      case Routes.welcome:
        screen = const WelcomeScreen();
      case Routes.guest:
        screen = const GuestScreen();
      case Routes.signIn:
        screen = const SignInScreen();
      case Routes.createAccount:
        screen = const CreateAccountScreen();
      case Routes.verify:
        screen = const VerifyScreen();
      case Routes.upgrade:
        final args = settings.arguments as UpgradeArgs? ??
            const UpgradeArgs(action: 'change this project');
        screen = UpgradeScreen(action: args.action);
      case Routes.migrate:
        screen = const MigrateScreen();
      case Routes.account:
        screen = const AccountScreen();
      case Routes.connected:
        screen = const ConnectedScreen();
      case Routes.dataControls:
        screen = const DataControlsScreen();
      case Routes.projects:
        screen = const ProjectsScreen();
      case Routes.branchMap:
        screen = const BranchMapScreen();
      case Routes.branchDetail:
        final args = settings.arguments as BranchArgs? ??
            const BranchArgs('main');
        screen = BranchDetailScreen(branchId: args.branchId);
      case Routes.newBranch:
        final args = settings.arguments as NewBranchArgs?;
        screen = NewBranchScreen(
          forkFromSnapshotId: args?.forkFromSnapshotId,
        );
      case Routes.snapshots:
        final args = settings.arguments as SnapshotsArgs?;
        screen = SnapshotsScreen(branchId: args?.branchId ?? 'main');
      case Routes.snapshotDetail:
        final args = settings.arguments as SnapshotArgs;
        screen = SnapshotDetailScreen(
          branchId: args.branchId,
          snapshotId: args.snapshotId,
        );
      case Routes.diff:
        final args = settings.arguments as DiffArgs;
        screen = DiffScreen(
          sourceId: args.sourceId,
          targetId: args.targetId,
        );
      case Routes.changeDetail:
        final args = settings.arguments as ChangeArgs;
        screen = ChangeDetailScreen(
          changeId: args.changeId,
          sourceId: args.sourceId,
          targetId: args.targetId,
        );
      case Routes.compare:
        screen = const CompareScreen();
      case Routes.restore:
        final args = settings.arguments as RestoreArgs;
        screen = RestoreScreen(
          branchId: args.branchId,
          snapshotId: args.snapshotId,
        );
      case Routes.restored:
        final args = settings.arguments as RestoredArgs;
        screen = RestoredScreen(
          branchId: args.branchId,
          snapshotId: args.snapshotId,
        );
      case Routes.merge:
        final args = settings.arguments as DiffArgs;
        screen = MergeScreen(
          sourceId: args.sourceId,
          targetId: args.targetId,
        );
      case Routes.conflict:
        final args = settings.arguments as ChangeArgs;
        screen = ConflictScreen(
          changeId: args.changeId,
          sourceId: args.sourceId,
          targetId: args.targetId,
        );
      case Routes.merged:
        final args = settings.arguments as MergedArgs;
        screen = MergedScreen(
          branchId: args.branchId,
          snapshotId: args.snapshotId,
          sourceId: args.sourceId,
        );
      case Routes.timeline:
        final args = settings.arguments as TimelineArgs?;
        screen = TimelineScreen(highlightScene: args?.highlightScene);
      case Routes.search:
        screen = const SearchScreen();
      case Routes.activity:
        screen = const ActivityScreen();
      case Routes.settings:
        screen = const SettingsScreen();
      default:
        screen = const ProjectsScreen();
    }
    return MaterialPageRoute<void>(
      builder: (_) => screen,
      settings: settings,
    );
  }
}

/// The "/" route's content: the splash while the store loads, then the
/// first screen — Projects for a returning session, Welcome for first
/// launch. Rebuilds on the controller (via [AnimatedBuilder]) so the
/// switch happens the moment `init()` completes.
class _StartupGate extends StatelessWidget {
  const _StartupGate();

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (controller.loading) return const _SplashScreen();
        return controller.hasSession
            ? const ProjectsScreen()
            : const WelcomeScreen();
      },
    );
  }
}

/// Splash shown while the store loads (local SharedPreferences — fast).
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppLogo.icon(size: 72),
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
