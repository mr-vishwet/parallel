import 'package:material_ui/material_ui.dart';

import '../core/constants.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../state/app_controller.dart';
import 'app_logo.dart';

/// The adaptive app shell: bottom navigation on phones, a sidebar on
/// desktop. Every screen renders through this widget, which is how the 30
/// routes cover both the mobile and the web V7 inventories.
///
/// Tabs (mobile bottom nav, V7 tab order): 0 Projects, 1 Branches,
/// 2 History, 3 Account. Deep screens pass [tab] -1 (no tab selected).
/// Auth screens pass [showNav] false.
class AdaptiveScaffold extends StatelessWidget {
  /// Creates an [AdaptiveScaffold].
  const AdaptiveScaffold({
    required this.title,
    required this.body,
    this.subtitle,
    this.tab = -1,
    this.actions,
    this.floatingActionButton,
    this.showNav = true,
    super.key,
  });

  /// The title.
  final String title;
  /// The subtitle.
  final String? subtitle;
  /// The body.
  final Widget body;
  /// The selected tab index (-1 for no tab).
  final int tab;
  /// The actions.
  final List<Widget>? actions;
  /// The floating action button.
  final Widget? floatingActionButton;
  /// Whether to show the navigation.
  final bool showNav;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= kDesktopBreakpoint;
        if (!desktop) return _buildMobile(context);
        return _buildDesktop(context);
      },
    );
  }

  Widget _buildMobile(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title),
            if (subtitle != null)
              Text(
                subtitle!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: ParallelPalette.muted,
                ),
              ),
          ],
        ),
        actions: actions,
      ),
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar:
          showNav ? _BottomNav(selectedTab: tab) : null,
    );
  }

  Widget _buildDesktop(BuildContext context) {
    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showNav) const _Sidebar(),
          Expanded(
            child: Column(
              children: [
                _DesktopHeader(
                  title: title,
                  subtitle: subtitle,
                  actions: actions,
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: kDesktopMaxWidth,
                      ),
                      child: body,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}

/// Bottom navigation for phones. Tab taps replace the current route so
/// the back stack never fills with tab switches.
class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.selectedTab});

  final int selectedTab;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    return NavigationBar(
      selectedIndex: selectedTab < 0 ? 0 : selectedTab,
      onDestinationSelected: (index) {
        if (index == selectedTab) return;
        switch (index) {
          case 0:
            Navigator.pushReplacementNamed(context, Routes.projects);
          case 1:
            Navigator.pushReplacementNamed(context, Routes.branchMap);
          case 2:
            Navigator.pushReplacementNamed(context, Routes.snapshots);
          case 3:
            Navigator.pushReplacementNamed(
              context,
              controller.signedIn
                  ? Routes.account
                  : controller.isGuest
                      ? Routes.guest
                      : Routes.welcome,
            );
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.folder_outlined),
          selectedIcon: Icon(Icons.folder),
          label: 'Projects',
        ),
        NavigationDestination(
          icon: Icon(Icons.account_tree_outlined),
          selectedIcon: Icon(Icons.account_tree),
          label: 'Branches',
        ),
        NavigationDestination(
          icon: Icon(Icons.history),
          selectedIcon: Icon(Icons.history),
          label: 'History',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Account',
        ),
      ],
    );
  }
}

/// Desktop sidebar: logo, nav, and the account slot at the bottom.
class _Sidebar extends StatelessWidget {
  const _Sidebar();

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final route = ModalRoute.of(context)?.settings.name ?? '';
    final project = controller.openProject;
    return Container(
      width: 260,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: ParallelPalette.paper2,
        border: Border(
          right: BorderSide(color: ParallelPalette.hairline),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: AppLogo.horizontal(iconSize: 30),
          ),
          if (project != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                project.name,
                style: AppTheme.mono(
                  size: 12,
                  color: ParallelPalette.muted,
                ),
              ),
            ),
          const Divider(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _NavItem(
                  icon: Icons.folder_outlined,
                  label: 'Projects',
                  route: Routes.projects,
                  active: route == Routes.projects,
                ),
                _NavItem(
                  icon: Icons.account_tree_outlined,
                  label: 'Branch map',
                  route: Routes.branchMap,
                  active: route == Routes.branchMap ||
                      route == Routes.branchDetail ||
                      route == Routes.newBranch,
                ),
                _NavItem(
                  icon: Icons.history,
                  label: 'Snapshots',
                  route: Routes.snapshots,
                  active: route == Routes.snapshots ||
                      route == Routes.snapshotDetail ||
                      route == Routes.restore ||
                      route == Routes.restored,
                ),
                _NavItem(
                  icon: Icons.compare_arrows,
                  label: 'Compare',
                  route: Routes.compare,
                  active: route == Routes.compare ||
                      route == Routes.diff ||
                      route == Routes.changeDetail ||
                      route == Routes.merge ||
                      route == Routes.conflict ||
                      route == Routes.merged,
                ),
                _NavItem(
                  icon: Icons.view_timeline_outlined,
                  label: 'Timeline',
                  route: Routes.timeline,
                  active: route == Routes.timeline,
                ),
                _NavItem(
                  icon: Icons.search,
                  label: 'Search',
                  route: Routes.search,
                  active: route == Routes.search,
                ),
                _NavItem(
                  icon: Icons.stream,
                  label: 'Activity',
                  route: Routes.activity,
                  active: route == Routes.activity,
                ),
                _NavItem(
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  route: Routes.settings,
                  active: route == Routes.settings,
                ),
              ],
            ),
          ),
          const Divider(),
          _AccountSlot(controller: controller),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.active,
  });

  final IconData icon;
  final String label;
  final String route;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: active
            ? ParallelPalette.cutRed.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: active
              ? null
              : () => Navigator.pushReplacementNamed(context, route),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: active
                      ? ParallelPalette.cutRed
                      : ParallelPalette.secondary,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        active ? FontWeight.w700 : FontWeight.w600,
                    color: active
                        ? ParallelPalette.cutRed
                        : ParallelPalette.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountSlot extends StatelessWidget {
  const _AccountSlot({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final signedIn = controller.signedIn;
    final name = signedIn ? controller.userName : 'Guest';
    final sub = signedIn ? controller.userEmail : 'View-only · demo';
    return Padding(
      padding: const EdgeInsets.all(16),
      child: InkWell(
        onTap: () => Navigator.pushReplacementNamed(
          context,
          signedIn
              ? Routes.account
              : controller.isGuest
                  ? Routes.guest
                  : Routes.welcome,
        ),
        borderRadius: BorderRadius.circular(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: ParallelPalette.cutRed,
              child: Text(
                name.isEmpty ? '?' : name[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    sub,
                    style: const TextStyle(
                      fontSize: 12,
                      color: ParallelPalette.muted,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: ParallelPalette.muted,
            ),
          ],
        ),
      ),
    );
  }
}

/// Desktop header: back button when there is somewhere to go back to,
/// title, subtitle, actions.
class _DesktopHeader extends StatelessWidget {
  const _DesktopHeader({required this.title, this.subtitle, this.actions});

  final String title;
  final String? subtitle;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: ParallelPalette.hairline),
        ),
      ),
      child: Row(
        children: [
          if (canPop)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
              tooltip: 'Back',
            ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(width: 12),
            Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 13,
                color: ParallelPalette.muted,
              ),
            ),
          ],
          const Spacer(),
          if (actions != null) ...actions!,
        ],
      ),
    );
  }
}

/// Shared page padding + scroll for screen bodies.
class ScreenBody extends StatelessWidget {
  /// Creates a [ScreenBody].
  const ScreenBody({required this.child, this.padding = 20, super.key});

  /// The child.
  final Widget child;
  /// The padding.
  final double padding;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: child,
    );
  }
}

/// A kicker line (small caps label above a heading), as in the V7 screens.
class Kicker extends StatelessWidget {
  /// Creates a [Kicker].
  const Kicker(this.text, {super.key});

  /// The text.
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: ParallelPalette.cutRed,
      ),
    );
  }
}
