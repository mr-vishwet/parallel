import 'package:material_ui/material_ui.dart';

import '../core/constants.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../state/app_controller.dart';
import '../widgets/adaptive_shell.dart';
import 'screen_helpers.dart';

/// 20 — Settings: project, sharing, sync, and the danger zone.
class SettingsScreen extends StatefulWidget {
  /// Creates a [SettingsScreen].
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _syncController;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _syncController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = AppScope.of(context);
    if (_syncController.text.isEmpty &&
        controller.settings.syncBaseUrl.isNotEmpty) {
      _syncController.text = controller.settings.syncBaseUrl;
    }
  }

  @override
  void dispose() {
    _syncController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final project = controller.openProject;
    if (project == null) {
      return const AdaptiveScaffold(
        title: 'Settings',
        tab: 3,
        body: Center(child: Text('No project is open.')),
      );
    }
    final settings = controller.settings;

    return AdaptiveScaffold(
      title: 'Settings',
      subtitle: project.name,
      tab: 3,
      body: ScreenBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Kicker('Project'),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  _Row(
                    icon: Icons.movie_outlined,
                    title: project.name,
                    sub: '${project.kind} · ${project.subtitle}',
                  ),
                  const Divider(),
                  const _Row(
                    icon: Icons.storage_outlined,
                    title: 'Storage',
                    sub: '${DemoFigures.storageOnDevice} on this device · '
                        'originals kept · demo figure',
                  ),
                  const Divider(),
                  _Row(
                    icon: Icons.download_outlined,
                    title: 'Export',
                    sub: 'All projects, branches and snapshots as JSON',
                    onTap: () => _export(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Kicker('Sharing'),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  _Row(
                    icon: Icons.people_outline,
                    title: 'Collaborators',
                    sub: controller.signedIn
                        ? '${controller.userName} · can branch and merge'
                        : 'Mara, Dev · both can branch and merge (demo)',
                  ),
                  const Divider(),
                  SwitchListTile(
                    secondary: const Icon(
                      Icons.link,
                      size: 18,
                      color: ParallelPalette.secondary,
                    ),
                    title: const Text(
                      'Review link',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      settings.reviewLinkOn
                          ? 'On · read-only cut shared'
                          : 'Off · turn on to share a read-only cut',
                      style: const TextStyle(
                        fontSize: 12,
                        color: ParallelPalette.muted,
                      ),
                    ),
                    value: settings.reviewLinkOn,
                    activeThumbColor: ParallelPalette.cutRed,
                    onChanged: (value) {
                      if (!requireAccount(
                        context,
                        'share a review link',
                      )) {
                        return;
                      }
                      controller.setReviewLink(value);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Kicker('Sync · sketch'),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sync server URL',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'The sync sketch server (see server/). Empty means '
                      'sync is off — everything stays local.',
                      style: TextStyle(
                        fontSize: 12,
                        color: ParallelPalette.muted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _syncController,
                      decoration: const InputDecoration(
                        hintText: 'http://localhost:8080',
                      ),
                      keyboardType: TextInputType.url,
                      autocorrect: false,
                      onSubmitted: (value) =>
                          controller.setSyncBaseUrl(value),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: _syncing
                              ? null
                              : () async {
                                  await controller.setSyncBaseUrl(
                                    _syncController.text,
                                  );
                                  setState(() => _syncing = true);
                                  final message =
                                      await controller.syncNow();
                                  setState(() => _syncing = false);
                                  if (context.mounted) {
                                    showMessage(context, message);
                                  }
                                },
                          child: Text(
                            _syncing ? 'Syncing…' : 'Sync now',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            controller.lastSyncMessage ??
                                'Not synced yet.',
                            style: const TextStyle(
                              fontSize: 12,
                              color: ParallelPalette.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Kicker('Danger zone'),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  _Row(
                    icon: Icons.archive_outlined,
                    title: project.archived
                        ? 'Unarchive project'
                        : 'Archive project',
                    sub: project.archived
                        ? 'Branches and snapshots are kept, read-only'
                        : 'Branches and snapshots are kept, read-only',
                    onTap: () async {
                      if (!requireAccount(
                        context,
                        'archive this project',
                      )) {
                        return;
                      }
                      final confirmed = await confirmDialog(
                        context,
                        title: project.archived
                            ? 'Unarchive ${project.name}?'
                            : 'Archive ${project.name}?',
                        message: project.archived
                            ? 'The project becomes editable again.'
                            : 'Branches and snapshots are kept, read-only. '
                                'You can unarchive it any time.',
                        confirmLabel: project.archived
                            ? 'Unarchive'
                            : 'Archive',
                      );
                      if (confirmed && context.mounted) {
                        await controller.setProjectArchived(
                          project,
                          !project.archived,
                        );
                      }
                    },
                  ),
                  const Divider(),
                  _Row(
                    icon: Icons.restart_alt,
                    title: 'Reset demo data',
                    sub: 'Restores the seeded demo workspace',
                    onTap: () async {
                      final confirmed = await confirmDialog(
                        context,
                        title: 'Reset the demo workspace?',
                        message: 'Your branches, snapshots and merges on '
                            'the demo projects will be replaced with the '
                            'seeded demo content. Your account stays.',
                        confirmLabel: 'Reset',
                        destructive: true,
                      );
                      if (confirmed && context.mounted) {
                        await controller.resetDemo();
                        if (context.mounted) {
                          showMessage(context, 'Demo workspace restored.');
                        }
                      }
                    },
                  ),
                  const Divider(),
                  _Row(
                    icon: Icons.person_outline,
                    title: 'Account',
                    sub: controller.signedIn
                        ? controller.userEmail
                        : 'Guest — sign in to keep your work',
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        controller.signedIn
                            ? Routes.account
                            : Routes.welcome,
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Center(
              child: Text(
                'PARALLEL · Build Specification · demo content is illustrative',
                style: TextStyle(
                  fontSize: 12,
                  color: ParallelPalette.muted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _export(BuildContext context) async {
    final controller = AppScope.of(context);
    await controller.copyExport();
    if (context.mounted) {
      showMessage(context, 'Export copied to the clipboard.');
    }
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.title,
    required this.sub,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String sub;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 18, color: ParallelPalette.secondary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      sub,
                      style: const TextStyle(
                        fontSize: 12,
                        color: ParallelPalette.muted,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: ParallelPalette.muted,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
