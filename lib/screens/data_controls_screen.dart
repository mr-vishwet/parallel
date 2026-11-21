import 'package:flutter/material.dart';

import '../core/routes.dart';
import '../core/theme.dart';
import '../services/export_service.dart';
import '../state/app_controller.dart';
import '../widgets/adaptive_shell.dart';
import 'screen_helpers.dart';

/// 30 — Data controls: sign out, export everything, or delete. Your
/// copies, your call.
class DataControlsScreen extends StatefulWidget {
  const DataControlsScreen({super.key});

  @override
  State<DataControlsScreen> createState() => _DataControlsScreenState();
}

class _DataControlsScreenState extends State<DataControlsScreen> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);

    return AdaptiveScaffold(
      title: 'Data controls',
      subtitle: 'Sign out & data controls',
      tab: 3,
      body: ScreenBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sign out, keep your work',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Signing out leaves your branches and snapshots on your '
              'account. This device keeps a local copy until you remove it.',
              style: TextStyle(
                fontSize: 15,
                color: ParallelPalette.secondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                child: Column(
                  children: const [
                    _ControlRow(
                      icon: Icons.logout,
                      title: 'Sign out',
                      sub: 'Back to the demo as a guest',
                    ),
                    Divider(),
                    _ControlRow(
                      icon: Icons.download_outlined,
                      title: 'Export everything',
                      sub: 'All projects, branches and snapshots as files',
                    ),
                    Divider(),
                    _ControlRow(
                      icon: Icons.delete_outline,
                      title: 'Delete account',
                      sub: 'Removes your account and your copies · the demo stays',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _busy
                    ? null
                    : () async {
                        setState(() => _busy = true);
                        await controller.signOut();
                        if (context.mounted) {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            Routes.welcome,
                            (route) => false,
                          );
                        }
                      },
                child: const Text('Sign out'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _busy
                    ? null
                    : () async {
                        setState(() => _busy = true);
                        try {
                          if (ExportService.canSaveFile) {
                            final path =
                                await controller.saveExport();
                            if (context.mounted) {
                              showMessage(
                                context,
                                'Export saved to $path',
                              );
                            }
                          } else {
                            await controller.copyExport();
                            if (context.mounted) {
                              showMessage(
                                context,
                                'Export copied to the clipboard.',
                              );
                            }
                          }
                        } catch (e) {
                          if (context.mounted) showError(context, e);
                        } finally {
                          if (mounted) setState(() => _busy = false);
                        }
                      },
                child: const Text('Export everything'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: ParallelPalette.danger,
                  side: const BorderSide(
                    color: ParallelPalette.danger,
                  ),
                ),
                onPressed: _busy
                    ? null
                    : () async {
                        final confirmed = await confirmDialog(
                          context,
                          title: 'Delete your account?',
                          message: 'This removes your account and your '
                              'copies of your projects. The demo stays. '
                              'Export first if you want a copy; deletion '
                              'cannot be undone.',
                          confirmLabel: 'Delete',
                          destructive: true,
                        );
                        if (!confirmed || !context.mounted) return;
                        setState(() => _busy = true);
                        try {
                          await controller.deleteAccount();
                          if (context.mounted) {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              Routes.welcome,
                              (route) => false,
                            );
                          }
                        } catch (e) {
                          if (context.mounted) showError(context, e);
                          if (mounted) setState(() => _busy = false);
                        }
                      },
                child: const Text('Delete account'),
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'Delete removes your account and your copies. Export first '
                'if you want a copy; deletion cannot be undone.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: ParallelPalette.secondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlRow extends StatelessWidget {
  const _ControlRow({
    required this.icon,
    required this.title,
    required this.sub,
  });

  final IconData icon;
  final String title;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
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
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  sub,
                  style: const TextStyle(
                    fontSize: 13,
                    color: ParallelPalette.secondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
